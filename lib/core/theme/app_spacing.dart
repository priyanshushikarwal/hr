import 'package:flutter/material.dart';

/// HRMS Design System - Spacing & Sizing Constants
/// Following an 8pt grid system for consistent spacing
class AppSpacing {
  AppSpacing._();

  // ============ BASE UNIT ============
  static const double unit = 8.0;

  // ============ SPACING SCALE ============
  static const double xs = 4.0; // 0.5x
  static const double sm = 8.0; // 1x
  static const double md = 16.0; // 2x
  static const double lg = 24.0; // 3x
  static const double xl = 32.0; // 4x
  static const double xxl = 48.0; // 6x
  static const double xxxl = 64.0; // 8x

  // ============ COMPONENT SPECIFIC ============
  /// Card padding
  static const double cardPadding = 20.0;
  static const double cardPaddingLarge = 24.0;
  static const double cardPaddingSmall = 16.0;

  /// Card margin
  static const double cardMargin = 16.0;
  static const double cardGap = 20.0;

  /// Section spacing
  static const double sectionSpacing = 32.0;
  static const double sectionSpacingLarge = 48.0;

  /// Sidebar
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double sidebarPadding = 16.0;
  static const double sidebarItemHeight = 48.0;
  static const double sidebarIconSize = 22.0;

  /// Header
  static const double headerHeight = 72.0;
  static const double headerPadding = 24.0;

  /// Page content
  static const double pageHorizontalPadding = 32.0;
  static const double pageVerticalPadding = 24.0;
  static const double pageMaxWidth = 1600.0;

  /// Form elements
  static const double inputHeight = 44.0;
  static const double inputHeightLarge = 52.0;
  static const double inputHeightSmall = 36.0;
  static const double inputBorderRadius = 10.0;
  static const double inputPaddingHorizontal = 14.0;
  static const double inputPaddingVertical = 12.0;
  static const double formFieldSpacing = 20.0;
  static const double formSectionSpacing = 32.0;

  /// Buttons
  static const double buttonHeight = 44.0;
  static const double buttonHeightLarge = 52.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonPaddingHorizontal = 20.0;
  static const double buttonPaddingVertical = 12.0;
  static const double buttonBorderRadius = 10.0;
  static const double buttonIconSize = 18.0;
  static const double buttonGap = 8.0;

  /// Table
  static const double tableRowHeight = 56.0;
  static const double tableHeaderHeight = 48.0;
  static const double tableCellPadding = 16.0;
  static const double tableColumnGap = 12.0;

  /// Modal / Dialog
  static const double modalWidth = 560.0;
  static const double modalWidthLarge = 720.0;
  static const double modalWidthSmall = 400.0;
  static const double modalPadding = 24.0;
  static const double modalBorderRadius = 16.0;

  /// Drawer
  static const double drawerWidth = 480.0;
  static const double drawerWidthLarge = 640.0;
  static const double drawerPadding = 24.0;

  /// Chips & Badges
  static const double chipHeight = 28.0;
  static const double chipHeightSmall = 22.0;
  static const double chipPaddingHorizontal = 12.0;
  static const double chipBorderRadius = 14.0;
  static const double badgeSize = 8.0;

  /// Avatar
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 56.0;
  static const double avatarSizeXLarge = 80.0;

  /// Icons
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;

  // ============ BORDER RADIUS ============
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0;

  /// Card border radius
  static const double cardRadius = 16.0;
  static const double cardRadiusLarge = 20.0;

  // ============ BORDER WIDTH ============
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;

  // ============ EDGE INSETS HELPERS ============
  static const EdgeInsets paddingAll = EdgeInsets.all(md);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);

  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: md);

  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontalPadding,
    vertical: pageVerticalPadding,
  );

  // ============ ANIMATION DURATIONS ============
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationVerySlow = Duration(milliseconds: 600);

  // ============ ANIMATION CURVES ============
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveBounce = Curves.elasticOut;
}
