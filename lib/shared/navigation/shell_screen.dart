import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../layouts/main_layout.dart';
import '../../features/notifications/presentation/widgets/notification_panel.dart';
import '../../features/auth/domain/providers/auth_providers.dart';
import '../../features/notifications/domain/providers/notification_providers.dart';

/// Shell Screen - Wrapper for main layout with auth context
class ShellScreen extends ConsumerWidget {
  final String currentRoute;
  final Widget child;

  const ShellScreen({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  String get _pageTitle {
    final routes = {
      '/dashboard': 'Dashboard',
      '/employees': 'Employee Master',
      '/kyc': 'KYC & Documents',
      '/experience': 'Work Experience',
      '/salary': 'Salary Structure',
      '/salary/office': 'Office Salary',
      '/salary/factory': 'Factory Salary',
      '/salary/payroll': 'Generate Payroll',
      '/salary/advances': 'Advance Tracking',
      '/offer-letters': 'Offer Letters',
      '/attendance': 'Attendance',
      '/leave-requests': 'Leave Requests',
      '/visits': 'Visit Tracking',
      '/tasks': 'Task Management',
      '/payments': 'Salary Slip & Payments',
      '/reports': 'Reports',
      '/admin': 'Admin & Roles',
      '/settings': 'Settings',
    };

    for (final entry in routes.entries) {
      if (currentRoute.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return 'HRMS';
  }

  String? get _pageSubtitle {
    switch (currentRoute) {
      case '/dashboard':
        return 'Overview and analytics';
      case '/employees':
        return 'Manage all employees';
      case '/kyc':
        return 'Document verification';
      case '/salary/office':
        return 'Manage office employee salaries';
      case '/salary/factory':
        return 'Manage factory employee salaries';
      case '/salary/payroll':
        return 'Advanced payroll calculation and processing';
      case '/salary/advances':
        return 'Track and manage employee advance payments';
      case '/offer-letters':
        return 'Create and manage offer letters';
      case '/attendance':
        return 'Track employee attendance';
      case '/leave-requests':
        return 'Review and manage leave applications';
      case '/visits':
        return 'Track and verify employee visit selfies & locations';
      case '/tasks':
        return 'Create, track, and manage daily tasks for your team';
      case '/payments':
        return 'Process salaries and payments';
      case '/reports':
        return 'Generate business reports';
      case '/admin':
        return 'Manage users and permissions';
      case '/settings':
        return 'Application settings';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return MainLayout(
      currentRoute: currentRoute,
      pageTitle: _pageTitle,
      pageSubtitle: _pageSubtitle,
      notificationCount: unreadCount,
      onNavigate: (route) {
        context.go(route);
      },
      onNotificationTap: () {
        _showNotificationPanel(context);
      },
      onProfileTap: () {
        _showProfileMenu(context, ref);
      },
      child: child,
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: const Material(elevation: 16, child: NotificationPanel()),
          ),
        );
      },
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(double.infinity, 80, 24, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? user?.email ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                user?.role.value.toUpperCase() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 8),
              Text('Profile'),
            ],
          ),
          onTap: () {},
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.settings_outlined, size: 18),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
          onTap: () => context.go('/settings'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () {
            ref.read(authProvider.notifier).logout();
          },
        ),
      ],
    );
  }
}
