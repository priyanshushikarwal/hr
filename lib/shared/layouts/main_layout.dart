import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'sidebar.dart';
import 'header.dart';

/// Main Desktop Layout Shell
/// Provides consistent layout with sidebar, header, and content area
class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;
  final String? pageSubtitle;
  final ValueChanged<String> onNavigate;
  final List<Widget>? headerActions;
  final bool showSearch;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.pageTitle,
    this.pageSubtitle,
    required this.onNavigate,
    this.headerActions,
    this.showSearch = true,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          AppSidebar(
            currentRoute: widget.currentRoute,
            onNavigate: widget.onNavigate,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                AppHeader(
                  title: widget.pageTitle,
                  subtitle: widget.pageSubtitle,
                  actions: widget.headerActions,
                  showSearch: widget.showSearch,
                  notificationCount: widget.notificationCount,
                  onNotificationTap: widget.onNotificationTap,
                  onProfileTap: widget.onProfileTap,
                ),

                // Page Content
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Content Card Wrapper
class ContentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final String? title;
  final Widget? titleAction;
  final bool showHeader;

  const ContentCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.title,
    this.titleAction,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeader && title != null) ...[
            Padding(
              padding: EdgeInsets.only(
                left: padding?.horizontal ?? AppSpacing.cardPadding,
                right: padding?.horizontal ?? AppSpacing.cardPadding,
                top: padding?.vertical ?? AppSpacing.cardPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title!, style: AppTypography.titleMedium),
                  if (titleAction != null) titleAction!,
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Flexible(
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid Layout for Dashboard Cards
class DashboardGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double gap;

  const DashboardGrid({
    super.key,
    required this.children,
    this.columns = 4,
    this.gap = AppSpacing.cardGap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns based on width
        int cols = columns;
        if (constraints.maxWidth < 1400) cols = 3;
        if (constraints.maxWidth < 1100) cols = 2;
        if (constraints.maxWidth < 700) cols = 1;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((child) {
            final width = (constraints.maxWidth - (gap * (cols - 1))) / cols;
            return SizedBox(width: width, child: child);
          }).toList(),
        );
      },
    );
  }
}

/// Two Column Layout
class TwoColumnLayout extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double leftFlex;
  final double rightFlex;
  final double gap;

  const TwoColumnLayout({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 2,
    this.rightFlex = 1,
    this.gap = AppSpacing.cardGap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex.toInt(), child: left),
        SizedBox(width: gap),
        Expanded(flex: rightFlex.toInt(), child: right),
      ],
    );
  }
}

/// Section with title
class Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const Section({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: AppTypography.bodySmall),
                  ],
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
