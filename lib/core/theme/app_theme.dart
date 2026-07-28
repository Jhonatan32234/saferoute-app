// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.slate800,
      error: AppColors.danger,
      onError: AppColors.white,
      errorContainer: AppColors.dangerBg,
      onErrorContainer: AppColors.riskHigh,
      surfaceContainerHighest: AppColors.slate50,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.slate900,
      secondary: AppColors.primary,
      onSecondary: AppColors.white,
      surface: AppColors.slate800,
      onSurface: AppColors.slate100,
      error: AppColors.riskHigh,
      onError: AppColors.white,
      errorContainer: AppColors.slate900,
      onErrorContainer: AppColors.riskHigh,
      surfaceContainerHighest: AppColors.slate900,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.brightness == Brightness.light 
          ? AppColors.slate50 
          : AppColors.slate900,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface.withOpacity(0.88),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.18,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),

      textTheme: textTheme,
    );
  }
}
