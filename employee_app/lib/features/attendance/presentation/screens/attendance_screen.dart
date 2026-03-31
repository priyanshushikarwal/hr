import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/attendance_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonth);

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(attendanceProvider(_monthKey));
    final canMarkAttendance = ref.watch(canMarkWifiAttendanceProvider);
    final currentWifi = ref.watch(currentWifiNameProvider);
    final officeWifiSession = ref.watch(officeWifiSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance'), centerTitle: true),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildMarkAttendanceCard(
              canMarkAttendance,
              currentWifi,
              officeWifiSession,
              attendance.valueOrNull ?? const [],
            ),
          ),
          SliverToBoxAdapter(child: _buildMonthPicker()),
          SliverToBoxAdapter(
            child: attendance.when(
              data: (records) => _buildSummary(records),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          attendance.when(
            data: (records) => SliverToBoxAdapter(child: _buildCalendar(records)),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Failed to load attendance')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkAttendanceCard(
    AsyncValue<bool> canMarkAttendance,
    AsyncValue<String?> currentWifi,
    AsyncValue<OfficeWifiSessionState> officeWifiSession,
    List<AttendanceRecord> records,
  ) {
    final isEnabled = canMarkAttendance.valueOrNull ?? false;
    final wifiName = currentWifi.valueOrNull;
    final session = officeWifiSession.valueOrNull;
    final todayRecord = _findTodayRecord(records);
    final connectedAt =
        session?.connectedAt ??
        _parseDateTime(todayRecord?.wifiConnectedAt);
    final markedAt =
        session?.attendanceMarkedAt ??
        _parseDateTime(todayRecord?.checkIn);
    final disconnectedAt =
        session?.disconnectedAt ??
        _parseDateTime(todayRecord?.wifiDisconnectedAt);
    final punchOutAt = _parseDateTime(todayRecord?.checkOut);
    final requiredPunchOutAt = _parseDateTime(todayRecord?.requiredPunchOutAt);
    final sessionWifiName = session?.wifiName ?? todayRecord?.officeWifiName;
    final hasMarkedAttendance =
        todayRecord != null && (todayRecord.checkIn?.isNotEmpty ?? false);
    final canPunchOut =
        hasMarkedAttendance &&
        !(todayRecord.checkOut?.isNotEmpty ?? false);
    final canMarkNow = isEnabled && !hasMarkedAttendance;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
          const Text(
            'Office Wi-Fi Attendance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            wifiName == null
                ? 'Connect to the configured office Wi-Fi to mark attendance.'
                : 'Connected Wi-Fi: $wifiName',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                ref.invalidate(currentWifiNameProvider);
                ref.invalidate(canMarkWifiAttendanceProvider);
                ref.invalidate(officeWifiSsidsProvider);
                ref.invalidate(officeWifiSessionProvider);
                ref.invalidate(attendanceProvider(_monthKey));
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Wi-Fi'),
            ),
          ),
          _buildWifiTimeline(
            sessionWifiName: sessionWifiName,
            connectedAt: connectedAt,
            markedAt: markedAt,
            disconnectedAt: disconnectedAt,
            requiredPunchOutAt: requiredPunchOutAt,
            punchOutAt: punchOutAt,
            isConnectedToOfficeWifi:
                session?.isConnectedToOfficeWifi ?? isEnabled,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canMarkNow ? _markAttendance : null,
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: Text(
                    hasMarkedAttendance
                        ? 'Attendance Marked'
                        : 'Mark Attendance',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canPunchOut ? _punchOut : null,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Punch Out'),
                ),
              ),
            ],
          ),
          if (canPunchOut)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Use Punch Out only when your workday actually ends.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildWifiTimeline({
    required String? sessionWifiName,
    required DateTime? connectedAt,
    required DateTime? markedAt,
    required DateTime? disconnectedAt,
    required DateTime? requiredPunchOutAt,
    required DateTime? punchOutAt,
    required bool isConnectedToOfficeWifi,
  }) {
    final hasSessionData =
        connectedAt != null ||
        markedAt != null ||
        disconnectedAt != null ||
        requiredPunchOutAt != null ||
        punchOutAt != null ||
        sessionWifiName != null;

    if (!hasSessionData) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sessionWifiName != null) ...[
            Text(
              'Office Wi-Fi: $sessionWifiName',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _TimelineRow(
            icon: Icons.wifi_rounded,
            label: 'Wi-Fi connected',
            value: _formatTimelineDateTime(connectedAt),
          ),
          const SizedBox(height: 8),
          _TimelineRow(
            icon: Icons.how_to_reg_rounded,
            label: 'Attendance marked',
            value: _formatTimelineDateTime(markedAt),
          ),
          const SizedBox(height: 8),
          _TimelineRow(
            icon: Icons.wifi_off_rounded,
            label: 'Wi-Fi disconnected',
            value: disconnectedAt != null
                ? _formatTimelineDateTime(disconnectedAt)
                : (isConnectedToOfficeWifi ? 'Still connected' : 'Not recorded yet'),
          ),
          const SizedBox(height: 8),
          _TimelineRow(
            icon: Icons.schedule_rounded,
            label: 'Required punch out',
            value: _formatTimelineDateTime(requiredPunchOutAt),
          ),
          const SizedBox(height: 8),
          _TimelineRow(
            icon: Icons.logout_rounded,
            label: 'Punch out',
            value: _formatTimelineDateTime(punchOutAt),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendance() async {
    try {
      await ref.read(attendanceActionProvider).markAttendanceFromEmployeeApp();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked successfully')),
        );
      }
      ref.invalidate(attendanceProvider(_monthKey));
      ref.invalidate(officeWifiSessionProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _punchOut() async {
    try {
      await ref.read(officeWifiSessionProvider.notifier).punchOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Punch out marked successfully')),
        );
      }
      ref.invalidate(attendanceProvider(_monthKey));
      ref.invalidate(officeWifiSessionProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildMonthPicker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSummary(List<AttendanceRecord> records) {
    final present = records
        .where((r) => r.status.toLowerCase() == 'present')
        .length;
    final late = records
        .where((r) => r.status.toLowerCase() == 'late')
        .length;
    final absent = records
        .where((r) => r.status.toLowerCase() == 'absent')
        .length;
    final halfDay = records
        .where((r) => r.status.toLowerCase().contains('half'))
        .length;
    final leave = records
        .where((r) => r.status.toLowerCase() == 'leave')
        .length;
    final visit = records
        .where((r) => r.status.toLowerCase() == 'visit')
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryChip('Present', present, AppColors.statusPresent),
          _SummaryChip('Late', late, AppColors.warning),
          _SummaryChip('Absent', absent, AppColors.statusAbsent),
          _SummaryChip('Half Day', halfDay, AppColors.statusHalfDay),
          _SummaryChip('Leave', leave, AppColors.statusLeave),
          _SummaryChip('Visit', visit, AppColors.statusVisit),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCalendar(List<AttendanceRecord> records) {
    final recordMap = <int, AttendanceRecord>{};
    for (final r in records) {
      final date = DateTime.tryParse(r.date);
      if (date != null) recordMap[date.toLocal().day] = r;
    }

    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    ).weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: daysInMonth + firstWeekday - 1,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final day = index - firstWeekday + 2;
              final record = recordMap[day];
              final status = record?.status ?? '';

              return _DayCell(day: day, status: status);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  AttendanceRecord? _findTodayRecord(List<AttendanceRecord> records) {
    final now = DateTime.now();
    for (final record in records) {
      final recordDate = DateTime.tryParse(record.date)?.toLocal();
      if (recordDate == null) continue;
      if (recordDate.year == now.year &&
          recordDate.month == now.month &&
          recordDate.day == now.day) {
        return record;
      }
    }
    return null;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  String _formatTimelineDateTime(DateTime? value) {
    if (value == null) return 'Not recorded yet';
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 3,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 8, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String status;
  const _DayCell({required this.day, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.statusPresent;
      case 'late':
        return AppColors.warning;
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
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday =
        day == DateTime.now().day &&
        DateTime.now().month == DateTime.now().month;

    return Container(
      decoration: BoxDecoration(
        color: status.isNotEmpty
            ? _color.withOpacity(0.15)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: status.isNotEmpty ? _color : AppColors.textPrimary,
            ),
          ),
          if (status.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
