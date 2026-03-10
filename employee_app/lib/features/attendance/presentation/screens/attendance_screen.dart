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

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance'), centerTitle: true),
      body: Column(
        children: [
          // Month Picker
          _buildMonthPicker(),
          const SizedBox(height: 8),

          // Summary
          attendance.when(
            data: (records) => _buildSummary(records),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Calendar Grid
          Expanded(
            child: attendance.when(
              data: (records) => _buildCalendar(records),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Failed to load attendance')),
            ),
          ),
        ],
      ),
    );
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
      child: Row(
        children: [
          _SummaryChip('Present', present, AppColors.statusPresent),
          const SizedBox(width: 8),
          _SummaryChip('Absent', absent, AppColors.statusAbsent),
          const SizedBox(width: 8),
          _SummaryChip('Half Day', halfDay, AppColors.statusHalfDay),
          const SizedBox(width: 8),
          _SummaryChip('Leave', leave, AppColors.statusLeave),
          const SizedBox(width: 8),
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
          Expanded(
            child: GridView.builder(
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
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
