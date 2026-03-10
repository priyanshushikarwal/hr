import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../profile/domain/providers/profile_providers.dart';
import '../../../attendance/domain/providers/attendance_providers.dart';
import '../../../leave/domain/providers/leave_providers.dart';
import '../../../notifications/domain/providers/notification_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(employeeProfileProvider);
    final auth = ref.watch(authProvider);
    final now = DateTime.now();
    final monthKey = DateFormat('yyyy-MM').format(now);
    final attendance = ref.watch(attendanceProvider(monthKey));
    final leaveState = ref.watch(leaveProvider);
    final notifState = ref.watch(notificationProvider);

    final name = profile.when(
      data: (e) => e?.firstName ?? auth.user?.name ?? 'Employee',
      loading: () => auth.user?.name ?? 'Employee',
      error: (_, __) => 'Employee',
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(employeeProfileProvider);
            ref.invalidate(attendanceProvider(monthKey));
            ref.read(leaveProvider.notifier).loadRequests();
            ref.read(notificationProvider.notifier).load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                _buildGreeting(name, context),
                const SizedBox(height: 24),

                // Stat Cards
                _buildStatCards(attendance, leaveState, notifState),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Recent Attendance
                _buildRecentAttendance(attendance),
                const SizedBox(height: 24),

                // Recent Notifications
                _buildRecentNotifications(notifState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(String name, BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatCards(
    AsyncValue<List<AttendanceRecord>> attendance,
    LeaveState leaveState,
    NotificationState notifState,
  ) {
    final records = attendance.when(
      data: (d) => d,
      loading: () => <AttendanceRecord>[],
      error: (_, __) => <AttendanceRecord>[],
    );

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecord = records.where((r) => r.date == todayKey).toList();
    final todayStatus = todayRecord.isNotEmpty
        ? todayRecord.first.status
        : 'Not Marked';

    final presentDays = records
        .where((r) => r.status.toLowerCase() == 'present')
        .length;
    final leavesTaken = leaveState.requests
        .where((l) => l.status == 'approved')
        .length;
    final pendingLeaves = leaveState.requests
        .where((l) => l.status == 'pending')
        .length;

    return Column(
      children: [
        Row(
          children: [
            _StatCard(
              title: "Today's Status",
              value: _capitalize(todayStatus),
              icon: Icons.access_time_rounded,
              color: _statusColor(todayStatus),
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: 'Present Days',
              value: presentDays.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              title: 'Leaves Taken',
              value: leavesTaken.toString(),
              icon: Icons.event_busy_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: 'Pending Requests',
              value: pendingLeaves.toString(),
              icon: Icons.hourglass_empty_rounded,
              color: AppColors.info,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickAction(
              icon: Icons.calendar_month_rounded,
              label: 'Attendance',
              color: AppColors.primary,
              onTap: () => _navigate(context, 1),
            ),
            _QuickAction(
              icon: Icons.post_add_rounded,
              label: 'Apply Leave',
              color: AppColors.infoDark,
              onTap: () => _navigate(context, 2),
            ),
            _QuickAction(
              icon: Icons.camera_alt_rounded,
              label: 'Visit Mode',
              color: AppColors.statusVisit,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _VisitModeRedirect()),
              ),
            ),
            _QuickAction(
              icon: Icons.person_rounded,
              label: 'Profile',
              color: AppColors.successDark,
              onTap: () => _navigate(context, 4),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  void _navigate(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 1:
        context.go('/attendance');
        break;
      case 2:
        context.go('/leave');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  Widget _buildRecentAttendance(AsyncValue<List<AttendanceRecord>> attendance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Attendance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        attendance.when(
          data: (records) {
            if (records.isEmpty) {
              return _emptyCard('No attendance records yet.');
            }
            final recent = records.take(5).toList();
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: recent.map((r) {
                  final date = DateTime.tryParse(r.date);
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          date != null ? DateFormat('dd').format(date) : '--',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _statusColor(r.status),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      date != null
                          ? DateFormat('EEEE, dd MMM').format(date)
                          : r.date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: _StatusChip(r.status),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _emptyCard('Failed to load attendance.'),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildRecentNotifications(NotificationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (state.items.where((n) => !n.isRead).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.items.where((n) => !n.isRead).length} new',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorDark,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.items.isEmpty)
          _emptyCard('No notifications')
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: state.items.take(3).map((n) {
                final dt = DateTime.tryParse(n.createdAt);
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? AppColors.backgroundSecondary
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: n.isRead
                          ? AppColors.textTertiary
                          : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    dt != null ? DateFormat('dd MMM, hh:mm a').format(dt) : '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.statusPresent;
      case 'absent':
        return AppColors.statusAbsent;
      case 'half day':
      case 'halfday':
        return AppColors.statusHalfDay;
      case 'leave':
        return AppColors.statusLeave;
      case 'visit':
        return AppColors.statusVisit;
      case 'holiday':
        return AppColors.statusHoliday;
      default:
        return AppColors.textTertiary;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = DashboardScreen._statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _cap(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _VisitModeRedirect extends StatelessWidget {
  const _VisitModeRedirect();
  @override
  Widget build(BuildContext context) {
    // Will be replaced by router navigation
    return const Scaffold(body: Center(child: Text('Visit Mode')));
  }
}
