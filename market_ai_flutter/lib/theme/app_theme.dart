import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5A2BDA);
  static const primaryDark = Color(0xFF4214C6);
  static const primaryLight = Color(0xFF7C4DFF);
  static const lavender = Color(0xFFF4F0FF);
  static const lavenderStrong = Color(0xFFE8DEFF);
  static const background = Color(0xFFFCFBFE);
  static const text = Color(0xFF18151F);
  static const muted = Color(0xFF77727F);
  static const border = Color(0xFFE9E5EF);
  static const success = Color(0xFF17A673);
  static const danger = Color(0xFFE35A6A);
  static const blue = Color(0xFF2879F3);
  static const instagram = Color(0xFFE74B8B);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
          height: 1.12,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: AppColors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFFAAA5B0), fontSize: 13.5),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
