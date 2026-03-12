import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light Mode
  static const lightBackground = Color(0xFFF8F8F8);
  static const lightPrimaryText = Color(0xFF000000);
  static const lightSecondaryText = Color(0xFF757575);
  static const lightBorder = Color(0xFFE0E0E0);
  static const lightAccent = Color(0xFF4A00E0);
  static const lightAccentActive = Color(0xFF8C6AFE);
  static const lightIcons = Color(0xFF000000);

  // Dark Mode
  static const darkBackground = Color(0xFF121212);
  static const darkPrimaryText = Color(0xFFFFFFFF);
  static const darkSecondaryText = Color(0xFFBBBBBB);
  static const darkBorder = Color(0xFF424242);
  static const darkAccent = Color(0xFF8C6AFE);
  static const darkIcons = Color(0xFFFFFFFF);

  // AMOLED Mode
  static const amoledBackground = Color(0xFF000000);
  static const amoledSurface = Color(0xFF0D0D0D);
  static const amoledSecondaryText = Color(0xFFA0A0A0);
  static const amoledText = Color(0xFFFFFFFF);
}

class AppTypography {
  static const String fontFamily = 'Poppins';

  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16, // Input Text
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 16, // Buttons
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
}

class AppTheme {
  static const double inputBorderRadius = 12.0;
  static const double buttonBorderRadius = 14.0;
  static const double cardBorderRadius = 16.0;

  static ThemeData getLightTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme = dynamicColorScheme?.brightness == Brightness.light
        ? dynamicColorScheme!
        : ColorScheme.fromSeed(
            seedColor: AppColors.lightAccent,
            brightness: Brightness.light,
            primary: AppColors.lightAccent,
            surface: AppColors.lightBackground,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.lightPrimaryText),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.lightPrimaryText),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.lightPrimaryText),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.lightPrimaryText),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightPrimaryText),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.lightPrimaryText),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.lightPrimaryText),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.lightPrimaryText),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.lightSecondaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: Colors.white),
          elevation: 2,
        ),
      ),
    );
  }

  static ThemeData getDarkTheme(ColorScheme? dynamicColorScheme, {bool isAmoled = false}) {
    final background = isAmoled ? AppColors.amoledBackground : AppColors.darkBackground;
    final surface = isAmoled ? AppColors.amoledSurface : AppColors.darkBackground;
    final secondaryText = isAmoled ? AppColors.amoledSecondaryText : AppColors.darkSecondaryText;

    final colorScheme = dynamicColorScheme?.brightness == Brightness.dark
        ? dynamicColorScheme!
        : ColorScheme.fromSeed(
            seedColor: AppColors.darkAccent,
            brightness: Brightness.dark,
            primary: AppColors.darkAccent,
            surface: surface,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTypography.fontFamily,
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.darkPrimaryText),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.darkPrimaryText),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkPrimaryText),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.darkPrimaryText),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkPrimaryText),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkPrimaryText),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkPrimaryText),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkPrimaryText),
        labelSmall: AppTypography.labelSmall.copyWith(color: secondaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isAmoled ? AppColors.amoledSurface : Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
    );
  }
}
