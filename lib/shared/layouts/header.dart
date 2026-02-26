import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/constants/app_icons.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/inputs.dart';

/// Top Header Bar
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showSearch;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final int notificationCount;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showSearch = true,
    this.onSearch,
    this.onNotificationTap,
    this.onProfileTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.headerPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),

          // Search Bar
          if (showSearch) ...[
            AppSearchField(
              hint: 'Search employees, reports...',
              onChanged: onSearch,
              width: 320,
            ),
            const SizedBox(width: AppSpacing.lg),
          ],

          // Custom Actions
          if (actions != null) ...[
            ...actions!,
            const SizedBox(width: AppSpacing.md),
          ],

          // Notifications
          _NotificationButton(
            count: notificationCount,
            onTap: onNotificationTap,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Divider
          Container(height: 32, width: 1, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),

          // Profile
          _ProfileButton(onTap: onProfileTap),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatefulWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationButton({required this.count, this.onTap});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: AppSpacing.durationFast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.backgroundSecondary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                _isHovered
                    ? AppIcons.notificationActive
                    : AppIcons.notification,
                size: 22,
                color: _isHovered ? AppColors.primary : AppColors.textSecondary,
              ),
              if (widget.count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      widget.count > 9 ? '9+' : widget.count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _ProfileButton({this.onTap});

  @override
  State<_ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<_ProfileButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: AppSpacing.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.backgroundSecondary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const UserAvatar(name: 'Admin User', size: 36, isOnline: true),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Admin User',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text('HR Manager', style: AppTypography.caption),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                AppIcons.chevronDown,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page Header with breadcrumb and actions
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;
  final Widget? leading;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            Row(
              children: breadcrumbs!.asMap().entries.map((entry) {
                final isLast = entry.key == breadcrumbs!.length - 1;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.value,
                      style: isLast
                          ? AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                            )
                          : AppTypography.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          AppIcons.chevronRight,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headlineMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: AppSpacing.md),
                ...actions!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
