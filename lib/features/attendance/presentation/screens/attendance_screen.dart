import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../domain/providers/attendance_providers.dart';
import '../../data/models/attendance_models.dart';
import '../../../../core/config/appwrite_config.dart';
import '../widgets/mark_attendance_dialog.dart';

/// Attendance Screen with Calendar + Table hybrid view
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();
  String? _selectedEmployee;
  final List<String> _viewModes = ['Calendar', 'Table'];
  String _currentView = 'Calendar';

  @override
  void initState() {
    super.initState();
    // Load attendance data on screen init
    Future.microtask(() {
      ref
          .read(attendanceProvider.notifier)
          .loadAttendance(
            month: _selectedMonth.month,
            year: _selectedMonth.year,
          );
    });
  }

  void _loadAttendance() {
    String? empId;
    if (_selectedEmployee != null && _selectedEmployee != 'All Employees') {
      final employeesState = ref.read(employeeListProvider);
      final match = employeesState.employees.where((e) {
        final label = '${e.employeeCode} - ${e.firstName} ${e.lastName}';
        return label == _selectedEmployee;
      }).toList();
      if (match.isNotEmpty) empId = match.first.id;
    }
    ref
        .read(attendanceProvider.notifier)
        .loadAttendance(
          month: _selectedMonth.month,
          year: _selectedMonth.year,
          employeeId: empId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Attendance',
            subtitle: 'Track and manage employee attendance',
            breadcrumbs: const ['Home', 'Attendance'],
            actions: [
              SecondaryButton(
                text: 'Export',
                icon: AppIcons.export,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Mark Attendance',
                icon: AppIcons.add,
                onPressed: () async {
                  final employees = ref
                      .read(employeeListProvider)
                      .employees
                      .where((e) => e.isActive)
                      .toList();
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) =>
                        MarkAttendanceDialog(employees: employees),
                  );
                  if (result == true) {
                    _loadAttendance();
                  }
                },
              ),
            ],
          ),

          // Filters Row
          _buildFiltersRow(),

          const SizedBox(height: AppSpacing.lg),

          // Attendance Summary Cards — dynamic
          _buildSummaryCards(attendanceState),

          const SizedBox(height: AppSpacing.lg),

          // Loading
          if (attendanceState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else
            // Calendar/Table View
            _currentView == 'Calendar'
                ? _buildCalendarView(attendanceState)
                : _buildTableView(attendanceState),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    final employeesState = ref.watch(employeeListProvider);
    final activeEmployees = employeesState.employees
        .where((e) => e.isActive)
        .toList();

    // Create dropdown items (All + active employees)
    final dropdownItems = [
      'All Employees',
      ...activeEmployees.map(
        (e) => '${e.employeeCode} - ${e.firstName} ${e.lastName}',
      ),
    ];

    // Ensure selected value is valid or reset to All
    if (_selectedEmployee != null &&
        !dropdownItems.contains(_selectedEmployee)) {
      _selectedEmployee = 'All Employees';
    }

    return ContentCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Employee Selector
          Expanded(
            flex: 2,
            child: AppDropdownField<String>(
              hint: 'Select Employee',
              value: _selectedEmployee ?? 'All Employees',
              items: dropdownItems,
              itemLabel: (item) => item,
              onChanged: (value) {
                setState(() => _selectedEmployee = value);
                _loadAttendance();
              },
              prefixIcon: AppIcons.employees,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Month/Year Picker
          Expanded(
            child: InkWell(
              onTap: _showMonthPicker,
              borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
              child: Container(
                height: AppSpacing.inputHeight,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.inputBorderRadius,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.calendar,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                        style: AppTypography.formInput,
                      ),
                    ),
                    Icon(
                      AppIcons.chevronDown,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // View Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: _viewModes.map((mode) {
                final isActive = _currentView == mode;
                return InkWell(
                  onTap: () => setState(() => _currentView = mode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.cardBackground
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isActive ? AppColors.cardShadow : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          mode == 'Calendar'
                              ? AppIcons.calendarDays
                              : AppIcons.table,
                          size: 16,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mode,
                          style: AppTypography.labelMedium.copyWith(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceState attendanceState) {
    final records = attendanceState.records;
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    // Count sundays in the month
    int weekendCount = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(_selectedMonth.year, _selectedMonth.month, d);
      if (dt.weekday == 7) weekendCount++; // Sunday
    }
    final workingDays = daysInMonth - weekendCount;

    final presentCount = records.where((r) => r.isPresent).length;
    final lateCount = records.where((r) => r.isLate).length;
    final absentCount = records.where((r) => r.isAbsent).length;
    final leaveCount = records.where((r) => r.isOnLeave).length;
    final halfDayCount = records.where((r) => r.isHalfDay).length;
    final totalOt = records.fold<double>(0, (sum, r) => sum + r.overtimeHours);

    return Row(
      children: [
        _AttendanceSummaryCard(
          title: 'Working Days',
          value: workingDays.toString(),
          subtitle: 'This month',
          icon: AppIcons.calendarDays,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'Present',
          value: presentCount.toString(),
          subtitle: workingDays > 0
              ? '${(presentCount / workingDays * 100).toStringAsFixed(1)}%'
              : '0%',
          icon: AppIcons.active,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'Late',
          value: lateCount.toString(),
          subtitle: workingDays > 0
              ? '${(lateCount / workingDays * 100).toStringAsFixed(1)}%'
              : '0%',
          icon: AppIcons.clock,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'Absent',
          value: absentCount.toString(),
          subtitle: workingDays > 0
              ? '${(absentCount / workingDays * 100).toStringAsFixed(1)}%'
              : '0%',
          icon: AppIcons.xCircle,
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'Leaves',
          value: '${leaveCount + halfDayCount}',
          subtitle: halfDayCount > 0
              ? '$leaveCount full + $halfDayCount half'
              : 'Approved',
          icon: AppIcons.calendar,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'OT Hours',
          value: totalOt.toStringAsFixed(0),
          subtitle: 'Total',
          icon: AppIcons.clock,
          color: AppColors.info,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildCalendarView(AttendanceState attendanceState) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final startWeekday = firstDayOfMonth.weekday;

    // Build a map of date -> status from real records
    final statusMap = <int, String>{};
    for (final record in attendanceState.records) {
      if (record.date.month == _selectedMonth.month &&
          record.date.year == _selectedMonth.year) {
        statusMap[record.date.day] = record.status;
      }
    }

    return ContentCard(
      title: 'Monthly Calendar',
      child: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  _LegendItem(color: AppColors.success, label: 'Present'),
                  const SizedBox(width: 16),
                  _LegendItem(color: AppColors.warning, label: 'Late'),
                  const SizedBox(width: 16),
                  _LegendItem(color: AppColors.error, label: 'Absent'),
                  const SizedBox(width: 16),
                  _LegendItem(color: AppColors.warningDark, label: 'Leave'),
                  const SizedBox(width: 16),
                  _LegendItem(color: AppColors.secondary, label: 'Half Day'),
                const SizedBox(width: 16),
                _LegendItem(
                  color: AppColors.textTertiary,
                  label: 'Weekend/Holiday',
                ),
                const SizedBox(width: 16),
                _LegendItem(
                  color: AppColors.backgroundSecondary,
                  label: 'Not Marked',
                ),
              ],
            ),
          ),

          // Weekday Headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Text(day, style: AppTypography.tableHeader),
                    ),
                  ),
                )
                .toList(),
          ),
          const Divider(),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.5,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final dayNumber = index - startWeekday + 2;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                dayNumber,
              );
              final isSunday = date.weekday == 7;
              final isFuture = date.isAfter(DateTime.now());

              // Get real status from attendance records or show blank
              String status;
              if (isSunday) {
                status = 'weekend';
              } else if (statusMap.containsKey(dayNumber)) {
                status = statusMap[dayNumber]!;
              } else if (isFuture) {
                status = 'future'; // future dates — blank
              } else {
                status = 'not_marked'; // past dates with no record
              }

              return _CalendarCell(
                day: dayNumber,
                status: status,
                isToday:
                    date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year,
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildTableView(AttendanceState attendanceState) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    // Build a map of day -> record
    final recordMap = <int, AttendanceRecord>{};
    for (final record in attendanceState.records) {
      if (record.date.month == _selectedMonth.month &&
          record.date.year == _selectedMonth.year) {
        recordMap[record.date.day] = record;
      }
    }

    return ContentCard(
      title: 'Attendance Details',
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 500,
        child: ListView.builder(
          itemCount: daysInMonth,
          itemBuilder: (context, index) {
            final dayNumber = index + 1;
            final date = DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              dayNumber,
            );
            final isSunday = date.weekday == 7;
            final record = recordMap[dayNumber];
            final isFuture = date.isAfter(DateTime.now());

            String status;
            if (isSunday) {
              status = 'weekend';
            } else if (record != null) {
              status = record.status;
            } else if (isFuture) {
              status = 'future';
            } else {
              status = 'not_marked';
            }

            return _AttendanceRow(
              date: date,
              status: status,
              checkIn: record?.checkIn != null
                  ? _formatTime(record!.checkIn!)
                  : null,
              checkOut: record?.checkOut != null
                  ? _formatTime(record!.checkOut!)
                  : null,
              hours: record?.hoursWorked ?? 0,
              ot: record?.overtimeHours ?? 0,
              selfieId: record?.selfieId,
              location: record?.location,
            );
          },
        ),
      ),
    ).animate().fadeIn();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _showMonthPicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (date != null) {
      setState(() => _selectedMonth = date);
      _loadAttendance();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AttendanceSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(value, style: AppTypography.titleLarge),
                    const SizedBox(width: 6),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCell extends StatefulWidget {
  final int day;
  final String status;
  final bool isToday;

  const _CalendarCell({
    required this.day,
    required this.status,
    this.isToday = false,
  });

  @override
  State<_CalendarCell> createState() => _CalendarCellState();
}

class _CalendarCellState extends State<_CalendarCell> {
  bool _isHovered = false;

  Color get _bgColor {
    switch (widget.status) {
      case 'present':
        return AppColors.successSurface;
      case 'late':
        return AppColors.warningSurface;
      case 'absent':
        return AppColors.errorSurface;
      case 'leave':
        return AppColors.warningSurface;
      case 'half_day':
        return AppColors.secondarySurface;
      case 'weekend':
        return AppColors.backgroundSecondary;
      case 'not_marked':
        return AppColors.cardBackground;
      case 'future':
        return AppColors.cardBackground;
      default:
        return AppColors.cardBackground;
    }
  }

  Color get _textColor {
    switch (widget.status) {
      case 'present':
        return AppColors.successDark;
      case 'late':
        return AppColors.warningDark;
      case 'absent':
        return AppColors.errorDark;
      case 'leave':
        return AppColors.warningDark;
      case 'half_day':
        return AppColors.secondaryDark;
      case 'weekend':
        return AppColors.textTertiary;
      case 'not_marked':
        return AppColors.textSecondary;
      case 'future':
        return AppColors.textTertiary;
      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        decoration: BoxDecoration(
          color: _isHovered ? _bgColor.withOpacity(0.8) : _bgColor,
          borderRadius: BorderRadius.circular(8),
          border: widget.isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : (widget.status == 'not_marked'
                    ? Border.all(
                        color: AppColors.border.withOpacity(0.5),
                        width: 1,
                      )
                    : null),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                widget.day.toString(),
                style: AppTypography.labelLarge.copyWith(
                  color: _textColor,
                  fontWeight: widget.isToday
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
            if (widget.status == 'present')
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final DateTime date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final double hours;
  final double ot;
  final String? selfieId;
  final String? location;

  const _AttendanceRow({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.hours = 0,
    this.ot = 0,
    this.selfieId,
    this.location,
  });

  String get _statusLabel {
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      case 'leave':
        return 'Leave';
      case 'half_day':
        return 'Half Day';
      case 'visit':
        return 'Visit';
      case 'weekend':
        return 'Weekend';
      case 'not_marked':
        return 'Not Marked';
      case 'future':
        return '-';
      default:
        return status;
    }
  }

  StatusType get _statusType {
    switch (status) {
      case 'present':
        return StatusType.success;
      case 'late':
        return StatusType.warning;
      case 'absent':
        return StatusType.error;
      case 'leave':
        return StatusType.warning;
      case 'half_day':
        return StatusType.info;
      case 'visit':
        return StatusType.info;
      case 'weekend':
        return StatusType.neutral;
      case 'not_marked':
        return StatusType.neutral;
      default:
        return StatusType.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Text(
                  '${date.day}'.padLeft(2, '0'),
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(width: 8),
                Text(days[date.weekday - 1], style: AppTypography.caption),
              ],
            ),
          ),

          // Status
          SizedBox(
            width: 110,
            child: StatusBadge(
              label: _statusLabel,
              type: _statusType,
              isSmall: true,
            ),
          ),

          // Check In
          Expanded(
            child: Text(
              checkIn ?? '--:--',
              style: AppTypography.tableCell.copyWith(
                color: checkIn != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
          ),

          // Check Out
          Expanded(
            child: Text(
              checkOut ?? '--:--',
              style: AppTypography.tableCell.copyWith(
                color: checkOut != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
          ),

          // Hours
          SizedBox(
            width: 80,
            child: Text(
              hours > 0 ? '${hours}h' : '-',
              style: AppTypography.tableCell.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // OT
          SizedBox(
            width: 80,
            child: ot > 0
                ? TextBadge(
                    label: '+${ot}h OT',
                    backgroundColor: AppColors.infoSurface,
                    textColor: AppColors.infoDark,
                    isSmall: true,
                  )
                : const Text('-'),
          ),

          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'visit' && selfieId != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showVisitDetails(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.infoSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: AppColors.infoDark,
                        ),
                      ),
                    ),
                  )
                else
                  AppIconButton(
                    icon: AppIcons.edit,
                    tooltip: 'Edit',
                    size: 28,
                    iconSize: 14,
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVisitDetails(BuildContext context) {
    if (selfieId == null) return;
    final imageUrl =
        '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.visitSelfiesBucketId}/files/$selfieId/view?project=${AppwriteConfig.projectId}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Visit Check-In Details', style: AppTypography.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 300,
                    width: double.infinity,
                    color: AppColors.backgroundSecondary,
                    child: Center(
                      child: Text('Image not available', style: AppTypography.bodySmall),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (location != null && location!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location Coordinates:\n$location',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
