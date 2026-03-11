import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'shell_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/employees/presentation/screens/employee_master_screen.dart';
import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/salary/presentation/screens/office_salary_screen.dart';
import '../../features/salary/presentation/screens/factory_salary_screen.dart';
import '../../features/offer_letter/presentation/screens/offer_letter_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/leave/presentation/screens/leave_approval_screen.dart';
import '../../features/visit/presentation/screens/visit_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';

/// App Router Configuration using GoRouter with Auth Guards
class AppRouter {
  AppRouter._();

  /// Creates a router that reacts to auth state changes
  static GoRouter createRouter(WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return GoRouter(
      initialLocation: '/dashboard',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isAuthenticated = authState.isAuthenticated;
        final isLoginRoute = state.uri.path == '/login';

        // If not authenticated and not on login page, redirect to login
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        // If authenticated and on login page, redirect to dashboard
        if (isAuthenticated && isLoginRoute) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        // Login Route (no shell)
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: _fadeTransition,
          ),
        ),

        // Shell Route - Main layout wrapper (auth required)
        ShellRoute(
          builder: (context, state, child) {
            return ShellScreen(currentRoute: state.uri.path, child: child);
          },
          routes: [
            // Dashboard
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Employee Master
            GoRoute(
              path: '/employees',
              name: 'employees',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const EmployeeMasterScreen(),
                transitionsBuilder: _fadeTransition,
              ),
              routes: [
                // Employee Details
                GoRoute(
                  path: ':id',
                  name: 'employee-details',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const _PlaceholderScreen(title: 'Employee Details'),
                    transitionsBuilder: _slideTransition,
                  ),
                ),
              ],
            ),

            // KYC & Documents
            GoRoute(
              path: '/kyc',
              name: 'kyc',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const KycScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Work Experience
            GoRoute(
              path: '/experience',
              name: 'experience',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const _PlaceholderScreen(title: 'Work Experience'),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Salary Structure
            GoRoute(
              path: '/salary',
              name: 'salary',
              redirect: (context, state) {
                if (state.uri.path == '/salary') {
                  return '/salary/office';
                }
                return null;
              },
              routes: [
                GoRoute(
                  path: 'office',
                  name: 'salary-office',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const OfficeSalaryScreen(),
                    transitionsBuilder: _fadeTransition,
                  ),
                ),
                GoRoute(
                  path: 'factory',
                  name: 'salary-factory',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const FactorySalaryScreen(),
                    transitionsBuilder: _fadeTransition,
                  ),
                ),
              ],
            ),

            // Offer Letters
            GoRoute(
              path: '/offer-letters',
              name: 'offer-letters',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const OfferLetterScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Attendance
            GoRoute(
              path: '/attendance',
              name: 'attendance',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AttendanceScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Leave Approval (NEW)
            GoRoute(
              path: '/leave-requests',
              name: 'leave-requests',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const LeaveApprovalScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Visit Tracking
            GoRoute(
              path: '/visits',
              name: 'visits',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const VisitScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Task Management
            GoRoute(
              path: '/tasks',
              name: 'tasks',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const TasksScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Salary Slip & Payments
            GoRoute(
              path: '/payments',
              name: 'payments',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const PaymentsScreen(),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Reports
            GoRoute(
              path: '/reports',
              name: 'reports',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const _PlaceholderScreen(title: 'Reports'),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Admin & Roles
            GoRoute(
              path: '/admin',
              name: 'admin',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const _PlaceholderScreen(title: 'Admin & Roles'),
                transitionsBuilder: _fadeTransition,
              ),
            ),

            // Settings
            GoRoute(
              path: '/settings',
              name: 'settings',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const _PlaceholderScreen(title: 'Settings'),
                transitionsBuilder: _fadeTransition,
              ),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => const _ErrorScreen(),
    );
  }

  /// Fade transition
  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
      child: child,
    );
  }

  /// Slide transition
  static Widget _slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Placeholder Screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'This screen is under construction',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// Error Screen
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
