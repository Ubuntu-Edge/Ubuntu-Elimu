import 'package:flutter/material.dart';
import 'colors.dart';

class UETypography {
  UETypography._();

  static const String _display = 'SpaceGrotesk';
  static const String _body    = 'Inter';

  static const TextStyle h1 = TextStyle(
    fontFamily: _display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: UEColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: UEColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _display,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: UEColors.textPrimary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: UEColors.textPrimary,
    height: 1.55,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: UEColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _body,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: UEColors.textMuted,
    letterSpacing: 0.08,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _body,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: UEColors.textDim,
  );
}