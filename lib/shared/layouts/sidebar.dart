import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/theme.dart';
import '../../core/constants/app_icons.dart';

/// Navigation item data
class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final List<NavItem>? children;
  final int? badgeCount;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.children,
    this.badgeCount,
  });
}

/// Sidebar navigation items
const List<NavItem> sidebarItems = [
  NavItem(label: 'Dashboard', icon: AppIcons.dashboard, route: '/dashboard'),
  NavItem(
    label: 'Employee Master',
    icon: AppIcons.employeeMaster,
    route: '/employees',
  ),
  NavItem(label: 'KYC & Documents', icon: AppIcons.kyc, route: '/kyc'),
  NavItem(
    label: 'Work Experience',
    icon: AppIcons.experience,
    route: '/experience',
  ),
  NavItem(
    label: 'Salary Structure',
    icon: AppIcons.salaryStructure,
    route: '/salary',
    children: [
      NavItem(
        label: 'Office Employees',
        icon: AppIcons.office,
        route: '/salary/office',
      ),
      NavItem(
        label: 'Factory Employees',
        icon: AppIcons.factory,
        route: '/salary/factory',
      ),
    ],
  ),
  NavItem(
    label: 'Offer Letters',
    icon: AppIcons.offerLetter,
    route: '/offer-letters',
    badgeCount: 3,
  ),
  NavItem(label: 'Attendance', icon: AppIcons.attendance, route: '/attendance'),
  NavItem(
    label: 'Leave Requests',
    icon: AppIcons.calendar,
    route: '/leave-requests',
  ),
  NavItem(
    label: 'Visit Tracking',
    icon: AppIcons.location,
    route: '/visits',
  ),
  NavItem(
    label: 'Salary Slip & Payments',
    icon: AppIcons.salarySlip,
    route: '/payments',
  ),
  NavItem(label: 'Reports', icon: AppIcons.reports, route: '/reports'),
  NavItem(label: 'Admin & Roles', icon: AppIcons.admin, route: '/admin'),
  NavItem(label: 'Settings', icon: AppIcons.settings, route: '/settings'),
];

/// Main Sidebar Widget
class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String? _expandedItem;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppSpacing.durationMedium,
      curve: AppSpacing.curveDefault,
      width: widget.isCollapsed
          ? AppSpacing.sidebarCollapsedWidth
          : AppSpacing.sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: const Border(right: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Header
          _buildLogoHeader(),

          const Divider(height: 1, color: AppColors.border),

          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: widget.isCollapsed
                    ? AppSpacing.sm
                    : AppSpacing.sidebarPadding,
              ),
              child: Column(
                children: sidebarItems.map((item) {
                  return _buildNavItem(item);
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Collapse Toggle
          _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Container(
      height: AppSpacing.headerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed
            ? AppSpacing.sm
            : AppSpacing.sidebarPadding,
      ),
      child: Row(
        children: [
          // Logo Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'HR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'HRMS',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text('Management System', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildNavItem(NavItem item) {
    final isActive =
        widget.currentRoute == item.route ||
        widget.currentRoute.startsWith('${item.route}/');
    final isExpanded = _expandedItem == item.route;
    final hasChildren = item.children?.isNotEmpty == true;

    return Column(
      children: [
        // Main Item
        _NavItemTile(
          item: item,
          isActive: isActive,
          isCollapsed: widget.isCollapsed,
          isExpanded: isExpanded,
          onTap: () {
            if (hasChildren) {
              setState(() {
                _expandedItem = isExpanded ? null : item.route;
              });
            } else {
              widget.onNavigate(item.route);
            }
          },
        ),

        // Children
        if (hasChildren && isExpanded && !widget.isCollapsed)
          AnimatedContainer(
            duration: AppSpacing.durationFast,
            child: Column(
              children: item.children!.map((child) {
                final isChildActive = widget.currentRoute == child.route;
                return _buildChildItem(child, isChildActive);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildChildItem(NavItem item, bool isActive) {
    return InkWell(
      onTap: () => widget.onNavigate(item.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        margin: const EdgeInsets.only(left: 40, bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              item.label,
              style: isActive
                  ? AppTypography.menuItemActive.copyWith(fontSize: 13)
                  : AppTypography.menuItem.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed
            ? AppSpacing.sm
            : AppSpacing.sidebarPadding,
      ),
      child: InkWell(
        onTap: widget.onToggleCollapse,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            mainAxisAlignment: widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.isCollapsed
                    ? AppIcons.menuExpand
                    : AppIcons.menuCollapse,
                size: 20,
                color: AppColors.textSecondary,
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: AppSpacing.sm),
                Text('Collapse', style: AppTypography.menuItem),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item tile
class _NavItemTile extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final bool isCollapsed;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<_NavItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.item.children?.isNotEmpty == true;

    Widget tile = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.primarySurface
              : (_isHovered
                    ? AppColors.backgroundSecondary
                    : Colors.transparent),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              height: AppSpacing.sidebarItemHeight,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 0 : AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: widget.isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    widget.item.icon,
                    size: AppSpacing.sidebarIconSize,
                    color: widget.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  if (!widget.isCollapsed) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: widget.isActive
                            ? AppTypography.menuItemActive
                            : AppTypography.menuItem,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.item.badgeCount != null &&
                        widget.item.badgeCount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.item.badgeCount.toString(),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (hasChildren)
                      AnimatedRotation(
                        turns: widget.isExpanded ? 0.5 : 0,
                        duration: AppSpacing.durationFast,
                        child: Icon(
                          AppIcons.chevronDown,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.isCollapsed) {
      tile = Tooltip(
        message: widget.item.label,
        preferBelow: false,
        verticalOffset: 0,
        child: tile,
      );
    }

    return tile;
  }
}
