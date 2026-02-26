import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';

/// Attendance Screen with Calendar + Table hybrid view
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();
  String? _selectedEmployee;
  final List<String> _viewModes = ['Calendar', 'Table'];
  String _currentView = 'Calendar';

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {},
              ),
            ],
          ),

          // Filters Row
          _buildFiltersRow(),

          const SizedBox(height: AppSpacing.lg),

          // Attendance Summary Cards
          _buildSummaryCards(),

          const SizedBox(height: AppSpacing.lg),

          // Calendar/Table View
          _currentView == 'Calendar' ? _buildCalendarView() : _buildTableView(),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return ContentCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Employee Selector
          Expanded(
            flex: 2,
            child: AppDropdownField<String>(
              hint: 'Select Employee',
              value: _selectedEmployee,
              items: const [
                'All Employees',
                'EMP001 - Rajesh Kumar',
                'EMP002 - Priya Sharma',
                'EMP003 - Amit Patel',
              ],
              itemLabel: (item) => item,
              onChanged: (value) => setState(() => _selectedEmployee = value),
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _AttendanceSummaryCard(
          title: 'Working Days',
          value: '24',
          subtitle: 'This month',
          icon: AppIcons.calendarDays,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'Present',
          value: '22',
          subtitle: '91.7%',
          icon: AppIcons.active,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'Absent',
          value: '2',
          subtitle: '8.3%',
          icon: AppIcons.xCircle,
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'Leaves',
          value: '3',
          subtitle: 'Approved',
          icon: AppIcons.calendar,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.md),
        _AttendanceSummaryCard(
          title: 'OT Hours',
          value: '12',
          subtitle: 'Total',
          icon: AppIcons.clock,
          color: AppColors.info,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildCalendarView() {
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
                _LegendItem(color: AppColors.error, label: 'Absent'),
                const SizedBox(width: 16),
                _LegendItem(color: AppColors.warning, label: 'Leave'),
                const SizedBox(width: 16),
                _LegendItem(color: AppColors.secondary, label: 'Half Day'),
                const SizedBox(width: 16),
                _LegendItem(
                  color: AppColors.textTertiary,
                  label: 'Weekend/Holiday',
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
              final isWeekend = date.weekday == 6 || date.weekday == 7;

              // Dummy status
              String status = 'present';
              if (isWeekend) {
                status = 'weekend';
              } else if (dayNumber == 5 || dayNumber == 12) {
                status = 'absent';
              } else if (dayNumber == 8) {
                status = 'leave';
              } else if (dayNumber == 15) {
                status = 'half_day';
              }

              return _CalendarCell(
                day: dayNumber,
                status: status,
                isToday:
                    date.day == DateTime.now().day &&
                    date.month == DateTime.now().month,
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildTableView() {
    return ContentCard(
      title: 'Attendance Details',
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 500,
        child: ListView.builder(
          itemCount: 15,
          itemBuilder: (context, index) {
            return _AttendanceRow(
              date: DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                index + 1,
              ),
              status: index == 4
                  ? 'absent'
                  : (index == 7 ? 'leave' : 'present'),
              checkIn: index == 4 ? null : '09:30 AM',
              checkOut: index == 4 ? null : '06:45 PM',
              hours: index == 4 ? 0 : 8.5,
              ot: index % 3 == 0 ? 2 : 0,
            );
          },
        ),
      ),
    ).animate().fadeIn();
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
      case 'absent':
        return AppColors.errorSurface;
      case 'leave':
        return AppColors.warningSurface;
      case 'half_day':
        return AppColors.secondarySurface;
      case 'weekend':
        return AppColors.backgroundSecondary;
      default:
        return AppColors.cardBackground;
    }
  }

  Color get _textColor {
    switch (widget.status) {
      case 'present':
        return AppColors.successDark;
      case 'absent':
        return AppColors.errorDark;
      case 'leave':
        return AppColors.warningDark;
      case 'half_day':
        return AppColors.secondaryDark;
      case 'weekend':
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
              : null,
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
            if (widget.status == 'present' && widget.status != 'weekend')
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
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

  const _AttendanceRow({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.hours = 0,
    this.ot = 0,
  });

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
            width: 100,
            child: StatusBadge(
              label: status == 'present'
                  ? 'Present'
                  : (status == 'leave' ? 'Leave' : 'Absent'),
              type: status == 'present'
                  ? StatusType.success
                  : (status == 'leave' ? StatusType.warning : StatusType.error),
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
}
