/// Utility class for formatting and validating Kenyan phone numbers
/// Handles conversion to international format (+254)
library;

class PhoneFormatter {
  /// Format phone number to international format (+254)
  /// Handles various input formats:
  /// - 07xxxxxxxx → +2547xxxxxxxx
  /// - +07xxxxxxxx → +2547xxxxxxxx
  /// - 011xxxxxxx → +2541xxxxxxxx
  /// - +011xxxxxxx → +2541xxxxxxx
  /// - 07 xxxxxxxx → +2547xxxxxxxx (with spaces)
  /// - 254xxxxxxxx → +254xxxxxxxx
  /// - +254xxxxxxxx → +254xxxxxxxx (already correct)
  static String? formatToInternational(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;

    // Remove all spaces, dashes, and parentheses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Remove leading + if present for processing
    bool hadPlus = cleaned.startsWith('+');
    if (hadPlus) {
      cleaned = cleaned.substring(1);
    }

    // Handle different formats
    if (cleaned.startsWith('254')) {
      // Already has country code: 254xxxxxxxx or +254xxxxxxxx
      return '+$cleaned';
    } else if (cleaned.startsWith('07')) {
      // Mobile number starting with 07: 07xxxxxxxx → +2547xxxxxxxx
      return '+254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('01')) {
      // Landline starting with 01: 011xxxxxxx → +2541xxxxxxx
      return '+254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') && cleaned.length == 9) {
      // Mobile without leading 0: 7xxxxxxxx → +2547xxxxxxxx
      return '+254$cleaned';
    } else if (cleaned.startsWith('1') && cleaned.length == 9) {
      // Landline without leading 0: 1xxxxxxxx → +2541xxxxxxxx
      return '+254$cleaned';
    }

    // If format not recognized, return original with + if it had one
    return hadPlus ? '+$cleaned' : cleaned;
  }

  /// Validate if phone number is a valid Kenyan number
  /// Returns true if valid, false otherwise
  static bool isValidKenyanNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return false;

    final formatted = formatToInternational(phone);
    if (formatted == null) return false;

    // Valid Kenyan numbers after formatting:
    // +2547xxxxxxxx (mobile, 12 chars total)
    // +2541xxxxxxxx (landline, 12 chars total)
    final cleanedFormatted = formatted.replaceAll('+', '');

    if (cleanedFormatted.length != 12) return false;
    if (!cleanedFormatted.startsWith('254')) return false;

    // Check if it's mobile (7) or landline (1)
    final fourthDigit = cleanedFormatted[3];
    return fourthDigit == '7' || fourthDigit == '1';
  }

  /// Get display format for phone number
  /// +254712345678 → 0712 345 678
  static String? getDisplayFormat(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;

    final formatted = formatToInternational(phone);
    if (formatted == null) return null;

    // Remove +254 and add 0 prefix, then add spaces
    if (formatted.startsWith('+254')) {
      final local = '0${formatted.substring(4)}'; // +254712345678 → 0712345678
      if (local.length == 10) {
        // 0712345678 → 0712 345 678
        return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
      }
      return local;
    }

    return formatted;
  }

  /// Extract country code from phone number
  static String getCountryCode(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '+254';

    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+254')) return '+254';
    if (cleaned.startsWith('254')) return '+254';

    return '+254'; // Default to Kenya
  }

  /// Format for input mask (as user types)
  /// Shows: +254 7XX XXX XXX
  static String formatAsTyping(String input) {
    // Remove all non-digits except +
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) return '';

    // Ensure it starts with +254
    if (!cleaned.startsWith('+')) {
      cleaned = '+254$cleaned';
    } else if (cleaned.startsWith('+') && !cleaned.startsWith('+254')) {
      cleaned = '+254${cleaned.substring(1)}';
    }

    // Format: +254 7XX XXX XXX
    if (cleaned.length <= 4) {
      return cleaned;
    } else if (cleaned.length <= 7) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
    } else if (cleaned.length <= 10) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    } else {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7, 10)} ${cleaned.substring(10)}';
    }
  }
}
