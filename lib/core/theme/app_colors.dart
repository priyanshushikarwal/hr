import 'package:flutter/material.dart';

/// HRMS Design System - Color Palette
/// Following the modern SaaS dashboard aesthetic with soft, calming colors
class AppColors {
  AppColors._();

  // ============ PRIMARY COLORS ============
  /// Soft Orange - Primary brand color for CTAs, active states
  static const Color primary = Color(0xFFFF8A3D);
  static const Color primaryLight = Color(0xFFFFB380);
  static const Color primaryDark = Color(0xFFE67320);
  static const Color primarySurface = Color(0xFFFFF4ED);

  // ============ SECONDARY COLORS ============
  /// Sky Blue - Secondary accent for information, links
  static const Color secondary = Color(0xFF6EC6FF);
  static const Color secondaryLight = Color(0xFFA8DCFF);
  static const Color secondaryDark = Color(0xFF4AA8E6);
  static const Color secondarySurface = Color(0xFFEDF7FF);

  // ============ ACCENT COLORS ============
  /// Mint Green - Accent for success states, positive metrics
  static const Color accent = Color(0xFFAEEA94);
  static const Color accentLight = Color(0xFFD4F5C4);
  static const Color accentDark = Color(0xFF8CD470);
  static const Color accentSurface = Color(0xFFF2FCE9);

  // ============ NEUTRAL COLORS ============
  /// Background colors
  static const Color background = Color(0xFFF7F9FC);
  static const Color backgroundSecondary = Color(0xFFEEF2F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFFFFFFFF);

  /// Text colors
  static const Color textPrimary = Color(0xFF1F2A44);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Border colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  /// Divider
  static const Color divider = Color(0xFFE5E7EB);

  // ============ SEMANTIC COLORS ============
  /// Success - Soft Green
  static const Color success = Color(0xFF34D399);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFF0FDF4);

  /// Warning - Amber
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);

  /// Error - Soft Red
  static const Color error = Color(0xFFF87171);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEF2F2);

  /// Info - Blue
  static const Color info = Color(0xFF60A5FA);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // ============ CHART COLORS ============
  static const List<Color> chartColors = [
    Color(0xFFFF8A3D), // Primary Orange
    Color(0xFF6EC6FF), // Sky Blue
    Color(0xFFAEEA94), // Mint Green
    Color(0xFFFBBF24), // Amber
    Color(0xFFA78BFA), // Purple
    Color(0xFFF472B6), // Pink
    Color(0xFF34D399), // Emerald
    Color(0xFF60A5FA), // Blue
  ];

  // ============ STATUS COLORS ============
  static const Color statusActive = Color(0xFF34D399);
  static const Color statusInactive = Color(0xFF9CA3AF);
  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusApproved = Color(0xFF10B981);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusDraft = Color(0xFF6B7280);

  // ============ GRADIENTS ============
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A3D), Color(0xFFFFB380)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6EC6FF), Color(0xFFA8DCFF)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAEEA94), Color(0xFFD4F5C4)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFBFC)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F9FC), Color(0xFFEEF2F7)],
  );

  // ============ SHADOWS ============
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1F2A44).withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF1F2A44).withOpacity(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF1F2A44).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF1F2A44).withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get hoverShadow => [
    BoxShadow(
      color: const Color(0xFF1F2A44).withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];
}
