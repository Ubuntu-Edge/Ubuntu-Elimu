import 'package:flutter/material.dart';

/// App Colors - Easy access to theme colors
/// Use AppColors.primary instead of AppTheme.primaryColor for convenience
class AppColors {
  static const Color primary = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00695C);
  static const Color primarySurface = Color(0xFFE0F2F1);
  static const Color secondary = Color(0xFF26A69A);
  
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  static const Color riskHigh = Color(0xFFDC2626);
  static const Color riskMedium = Color(0xFFF97316);
  static const Color riskLow = Color(0xFF22C55E);
  static const Color riskCritical = Color(0xFF7F1D1D);
}

/// CHW Augment App Theme - Professional Medical App Design
/// Based on the provided UI mockup with green color scheme
class AppTheme {
  // Primary Colors (Teal/Green Medical Theme)
  static const Color primaryColor = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00695C);
  static const Color primarySurface = Color(0xFFE0F2F1);

  // Accent Colors
  static const Color accentColor = Color(0xFF26A69A);
  static const Color accentLight = Color(0xFF80CBC4);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Risk Level Colors
  static const Color riskHigh = Color(0xFFDC2626);
  static const Color riskMedium = Color(0xFFF97316);
  static const Color riskLow = Color(0xFF22C55E);
  static const Color riskCritical = Color(0xFF7F1D1D);

  // Category Colors (for specialties/departments)
  static const Color categoryNephrology = Color(0xFF8B5CF6);
  static const Color categoryCardiology = Color(0xFFEC4899);
  static const Color categoryOrthopedics = Color(0xFF06B6D4);
  static const Color categoryDermatology = Color(0xFFF472B6);
  static const Color categoryPediatrics = Color(0xFF34D399);
  static const Color categoryPathology = Color(0xFF6366F1);
  static const Color categoryOncology = Color(0xFFA855F7);
  static const Color categorySurgery = Color(0xFF14B8A6);
  static const Color categoryRadiology = Color(0xFF64748B);

  // Font Family - Using system fonts that look like Calibri
  static const String fontFamily = 'Roboto'; // Cross-platform alternative to Calibri

  // Font Sizes (base size 10, scaled appropriately)
  static const double fontSizeXS = 10.0;
  static const double fontSizeSM = 11.0;
  static const double fontSizeMD = 12.0;
  static const double fontSizeLG = 14.0;
  static const double fontSizeXL = 16.0;
  static const double fontSizeXXL = 18.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeading = 24.0;
  static const double fontSizeDisplay = 28.0;

  // Spacing - lowercase aliases for convenience
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  
  // Spacing - original uppercase
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingSection = 32.0;

  // Border Radius - lowercase aliases
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 50.0;
  
  // Border Radius - original uppercase
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusRound = 50.0;
  
  // Text Styles for easy access
  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeHeading,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLG,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMD,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSM,
    color: textSecondary,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMD,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // Shadows - lowercase aliases
  static List<BoxShadow> get shadowSm => shadowSM;
  static List<BoxShadow> get shadowMd => shadowMD;
  static List<BoxShadow> get shadowLg => shadowLG;
  
  // Shadows - original uppercase
  static List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: Colors.black.withAlpha(13),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: Colors.black.withAlpha(20),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: Colors.black.withAlpha(26),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXL,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
        iconTheme: IconThemeData(color: textOnPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        margin: const EdgeInsets.symmetric(vertical: spacingSM),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSizeMD,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSizeMD,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSizeMD,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLG,
          vertical: spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeMD,
          color: textLight,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeMD,
          color: textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primarySurface,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXS,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSM,
          vertical: spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXS,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXS,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: spacingLG,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeDisplay,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeHeading,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXXL,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXL,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeLG,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXL,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeLG,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeMD,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeLG,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeMD,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeSM,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeMD,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeSM,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeXS,
          fontWeight: FontWeight.w500,
          color: textLight,
        ),
      ),
    );
  }
}

/// Extension methods for easy access to theme colors
extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
