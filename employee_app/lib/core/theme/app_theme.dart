import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HRMS Mobile Theme — matches Desktop design language
class AppColors {
  AppColors._();

  // Primary — Soft Orange
  static const Color primary = Color(0xFFFF8A3D);
  static const Color primaryLight = Color(0xFFFFB380);
  static const Color primaryDark = Color(0xFFE67320);
  static const Color primarySurface = Color(0xFFFFF4ED);

  // Secondary — Sky Blue
  static const Color secondary = Color(0xFF6EC6FF);
  static const Color secondarySurface = Color(0xFFEDF7FF);

  // Backgrounds
  static const Color background = Color(0xFFF7F9FC);
  static const Color backgroundSecondary = Color(0xFFEEF2F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF7F9FC);

  // Text
  static const Color textPrimary = Color(0xFF1F2A44);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color successDark = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFF0FDF4);

  static const Color warning = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);

  static const Color error = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // Status
  static const Color statusPresent = Color(0xFF34D399);
  static const Color statusAbsent = Color(0xFFEF4444);
  static const Color statusHalfDay = Color(0xFFFBBF24);
  static const Color statusLeave = Color(0xFF60A5FA);
  static const Color statusVisit = Color(0xFFA78BFA);
  static const Color statusHoliday = Color(0xFFF472B6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A3D), Color(0xFFFFB380)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A3D), Color(0xFFE67320)],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.cardBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
