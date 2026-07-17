// Validation utilities for authentication fields
// Based on backend validation rules

/// Validation utilities for authentication fields matching backend rules
class AuthValidation {
  /// Weak PINs that are rejected
  static const List<String> weakPins = [
    '0000', '1111', '2222', '3333', '4444',
    '5555', '6666', '7777', '8888', '9999',
    '1234', '4321', '1122', '2211',
  ];

  /// Validate phone number in E.164 format
  /// Accepts formats like: 0712345678, +254712345678, 254712345678
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and dashes
    String cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Check minimum length
    if (cleaned.length < 10) {
      return 'Phone number is too short';
    }

    // Check maximum length
    if (cleaned.length > 20) {
      return 'Phone number is too long';
    }

    return null;
  }

  /// Format phone number to E.164 format for API
  static String formatPhoneNumber(String phone) {
    // Remove spaces and dashes
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // If starts with 0, replace with +254 (Kenya)
    if (cleaned.startsWith('0')) {
      cleaned = '+254${cleaned.substring(1)}';
    }
    // If doesn't start with +, add it
    else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }

  /// Validate PIN
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    // Check length (4-6 digits)
    if (value.length < 4) {
      return 'PIN must be at least 4 digits';
    }

    if (value.length > 6) {
      return 'PIN must be at most 6 digits';
    }

    // Check if only digits
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN must contain only digits';
    }

    // Check for weak PINs
    if (weakPins.contains(value)) {
      return 'This PIN is too common, please choose a different one';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      if (isRequired) {
        return 'Password is required';
      }
      return null;
    }

    // Minimum 8 characters
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Maximum 128 characters
    if (value.length > 128) {
      return 'Password is too long';
    }

    // Must contain uppercase
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Must contain lowercase
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Must contain digit
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one digit';
    }

    return null;
  }

  /// Validate name (first or last)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    // Minimum 2 characters
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    // Maximum 100 characters
    if (value.length > 100) {
      return '$fieldName is too long';
    }

    // Only letters, spaces, hyphens, apostrophes
    if (!RegExp(r"^[a-zA-Z\s'\-]+$").hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Format name to title case
  static String formatName(String name) {
    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Validate email (optional field)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }

    // Basic email format check
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate confirm PIN matches
  static String? validateConfirmPin(String? value, String originalPin) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your PIN';
    }

    if (value != originalPin) {
      return 'PINs do not match';
    }

    return null;
  }

  /// Validate confirm password matches
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Check password strength and return score (0-4)
  static int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Normalize to 0-4 scale
    return (score / 6 * 4).round().clamp(0, 4);
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }
}
