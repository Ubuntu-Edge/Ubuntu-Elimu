/// Utility functions for age calculation from date of birth
library;

class AgeCalculator {
  /// Calculate age in years and months from date of birth
  /// Returns a map with 'years', 'months', and 'totalMonths'
  static Map<String, int> calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();

    int years = now.year - dateOfBirth.year;
    int months = now.month - dateOfBirth.month;

    // Adjust if birthday hasn't occurred this year yet
    if (months < 0 || (months == 0 && now.day < dateOfBirth.day)) {
      years--;
      months += 12;
    }

    // Adjust months if day hasn't occurred this month yet
    if (now.day < dateOfBirth.day && months > 0) {
      months--;
    }

    final totalMonths = (years * 12) + months;

    return {
      'years': years,
      'months': months,
      'totalMonths': totalMonths,
    };
  }

  /// Get a formatted age string
  /// For children under 2 years, shows months
  /// For others, shows years
  static String getAgeString(DateTime dateOfBirth) {
    final ageData = calculateAge(dateOfBirth);
    final years = ageData['years']!;
    final months = ageData['months']!;

    if (years < 2) {
      final totalMonths = ageData['totalMonths']!;
      if (totalMonths == 0) {
        return 'Less than 1 month';
      } else if (totalMonths == 1) {
        return '1 month';
      } else {
        return '$totalMonths months';
      }
    } else if (years == 1) {
      if (months == 0) {
        return '1 year';
      } else if (months == 1) {
        return '1 year 1 month';
      } else {
        return '1 year $months months';
      }
    } else {
      if (months == 0) {
        return '$years years';
      } else if (months == 1) {
        return '$years years 1 month';
      } else {
        return '$years years $months months';
      }
    }
  }

  /// Get just the age in years (for display purposes)
  static int getAgeInYears(DateTime dateOfBirth) {
    return calculateAge(dateOfBirth)['years']!;
  }

  /// Get age in months (useful for infants/toddlers)
  static int getAgeInMonths(DateTime dateOfBirth) {
    return calculateAge(dateOfBirth)['totalMonths']!;
  }

  /// Check if date of birth is valid (not in future)
  static bool isValidDateOfBirth(DateTime dateOfBirth) {
    return dateOfBirth.isBefore(DateTime.now()) ||
        dateOfBirth.isAtSameMomentAs(DateTime.now());
  }

  /// Format DateTime to API date format (YYYY-MM-DD)
  static String formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse API date format (YYYY-MM-DD) to DateTime
  static DateTime? parseDateFromApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
