import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class UETheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: UEColors.accent,
      scaffoldBackgroundColor: UEColors.bg,
      fontFamily: 'Inter',
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        // Allow fallback or overrides
      ),
      colorScheme: const ColorScheme.dark(
        primary: UEColors.accent,
        secondary: UEColors.violet,
        surface: UEColors.surface,
        error: UEColors.pdfFg,
      ),
    );
  }
}
