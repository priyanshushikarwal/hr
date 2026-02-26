import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layouts/main_layout.dart';

/// Shell Screen - Wrapper for main layout
class ShellScreen extends StatelessWidget {
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
      '/offer-letters': 'Offer Letters',
      '/attendance': 'Attendance',
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
        return 'January 26, 2024';
      case '/employees':
        return 'Manage all employees';
      case '/kyc':
        return 'Document verification';
      case '/salary/office':
        return 'Manage office employee salaries';
      case '/salary/factory':
        return 'Manage factory employee salaries';
      case '/offer-letters':
        return 'Create and manage offer letters';
      case '/attendance':
        return 'Track employee attendance';
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
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: currentRoute,
      pageTitle: _pageTitle,
      pageSubtitle: _pageSubtitle,
      onNavigate: (route) {
        context.go(route);
      },
      child: child,
    );
  }
}
