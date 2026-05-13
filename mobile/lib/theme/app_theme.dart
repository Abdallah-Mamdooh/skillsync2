import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentOrange,
        background: Colors.white,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
      ).copyWith(
        // Override any specific colors if needed
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: 2,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.accentOrange,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentOrange,
        background: AppColors.backgroundTeal,
        surface: AppColors.surfaceDark,
        onPrimary: Colors.black87,
        onSurface: Colors.white,
      ).copyWith(
        // Override any specific colors if needed
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 2,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.accentOrange,
        ),
      ),
    );
  }
}
