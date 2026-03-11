import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const lightBackground = Color(0xFFF8F8F8);
  static const lightPrimaryText = Color(0xFF000000);
  static const lightSecondaryText = Color(0xFF757575);
  static const lightBorder = Color(0xFFE0E0E0);
  static const lightAccent = Color(0xFF4A00E0);
  static const lightAccentActive = Color(0xFF8C6AFE);

  // Dark Mode
  static const darkBackground = Color(0xFF0F0F0F);
  static const darkPrimaryText = Color(0xFFFFFFFF);
  static const darkSecondaryText = Color(0xFFBBBBBB);
  static const darkBorder = Color(0xFF262626);
  static const darkAccent = Color(0xFF8C6AFE);

  // AMOLED Mode
  static const amoledBackground = Color(0xFF000000);
  static const amoledSurface = Color(0xFF0D0D0D);
  static const amoledSecondaryText = Color(0xFFA0A0A0);
}

class AppTypography {
  static const String fontFamily = 'Poppins';

  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
  );

  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
