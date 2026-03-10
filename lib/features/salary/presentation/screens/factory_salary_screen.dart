import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';
import '../../../employees/domain/providers/employee_providers.dart';

/// Factory Salary Screen - Daily wage tracking for factory workers
class FactorySalaryScreen extends ConsumerStatefulWidget {
  const FactorySalaryScreen({super.key});

  @override
  ConsumerState<FactorySalaryScreen> createState() =>
      _FactorySalaryScreenState();
}

class _FactorySalaryScreenState extends ConsumerState<FactorySalaryScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedShift;

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeListProvider);
    final factoryEmployees = employeesState.employees
        .where((e) => e.isActive && e.isFactory)
        .toList();

    // Build entries from real factory employees
    final entries = factoryEmployees.map((emp) {
      return _FactoryEntry(
        employeeId: emp.employeeCode,
        name: emp.fullName,
        department: emp.department,
        hoursWorked: 0,
        kva: 0,
        rate: 0,
        basicAmount: 0,
        ot: 0,
        otAmount: 0,
        total: 0,
      );
    }).toList();

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Factory Employee Salary',
            subtitle: 'Track daily wages and lot-wise payments',
            breadcrumbs: const ['Home', 'Salary Structure', 'Factory'],
            actions: [
              SecondaryButton(
                text: 'Import Data',
                icon: AppIcons.import_,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Add Entry',
                icon: AppIcons.add,
                onPressed: () => _showAddEntryDialog(context),
              ),
            ],
          ),

          // Filters Row
          _buildFiltersRow(),

          const SizedBox(height: AppSpacing.lg),

          // Summary Cards
          _buildSummaryCards(entries),

          const SizedBox(height: AppSpacing.lg),

          if (employeesState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (factoryEmployees.isEmpty)
            ContentCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        AppIcons.factory,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No factory employees found. Add factory employees first.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Daily Entries Table
            _buildEntriesTable(entries),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return ContentCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Date Picker
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(context),
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
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTypography.formInput,
                    ),
                    const Spacer(),
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

          // Shift Selector
          Expanded(
            child: AppDropdownField<String>(
              hint: 'All Shifts',
              value: _selectedShift,
              items: const ['General Shift', 'Morning Shift', 'Night Shift'],
              itemLabel: (item) => item,
              onChanged: (value) => setState(() => _selectedShift = value),
              prefixIcon: AppIcons.clock,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Quick Navigation
          Row(
            children: [
              AppIconButton(
                icon: AppIcons.chevronLeft,
                tooltip: 'Previous Day',
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
              ),
              const SizedBox(width: 4),
              GhostButton(
                text: 'Today',
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
              ),
              const SizedBox(width: 4),
              AppIconButton(
                icon: AppIcons.chevronRight,
                tooltip: 'Next Day',
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<_FactoryEntry> entries) {
    final totalWorkers = entries.length;
    final totalHours = entries.fold<double>(0, (sum, e) => sum + e.hoursWorked);
    final totalKva = entries.fold<double>(0, (sum, e) => sum + e.kva);
    final totalAmount = entries.fold<double>(0, (sum, e) => sum + e.total);

    return Row(
      children: [
        _SummaryCard(
          title: 'Workers Present',
          value: totalWorkers.toString(),
          icon: AppIcons.employees,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Total Hours',
          value: '${totalHours.toInt()}h',
          icon: AppIcons.clock,
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Total KVA',
          value: totalKva.toInt().toString(),
          icon: AppIcons.chart,
          color: AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Total Wages',
          value: '₹${_formatNumber(totalAmount.toInt())}',
          icon: AppIcons.money,
          color: AppColors.success,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildEntriesTable(List<_FactoryEntry> entries) {
    return ContentCard(
      title: 'Daily Entries - ${_formatDate(_selectedDate)}',
      titleAction: Row(
        children: [
          GhostButton(
            text: 'Approve All',
            icon: AppIcons.approve,
            color: AppColors.success,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          GhostButton(text: 'Export', icon: AppIcons.export, onPressed: () {}),
        ],
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _TableHeader('EMPLOYEE', flex: 2),
                _TableHeader('SHIFT', flex: 1),
                _TableHeader('HOURS', flex: 1),
                _TableHeader('KVA/UNITS', flex: 1),
                _TableHeader('RATE', flex: 1),
                _TableHeader('BASIC', flex: 1),
                _TableHeader('OT', flex: 1),
                _TableHeader('TOTAL', flex: 1),
                _TableHeader('STATUS', flex: 1),
                const SizedBox(width: 80),
              ],
            ),
          ),

          // Table Rows
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            return _EntryRow(entry: entry);
          }),

          // Add New Row Button
          InkWell(
            onTap: () => _showAddEntryDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.add, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Entry',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _showAddEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Entry'),
        content: const Text('Add entry form will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                Text(value, style: AppTypography.titleLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeader(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, style: AppTypography.tableHeader),
    );
  }
}

class _EntryRow extends StatefulWidget {
  final _FactoryEntry entry;

  const _EntryRow({required this.entry});

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.backgroundSecondary
              : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // Employee
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  UserAvatar(name: widget.entry.name, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.name,
                          style: AppTypography.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.entry.employeeId} • ${widget.entry.department}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Shift
            Expanded(child: Text('General', style: AppTypography.tableCell)),
            // Hours
            Expanded(
              child: Text(
                '${widget.entry.hoursWorked}h',
                style: AppTypography.tableCell,
              ),
            ),
            // KVA
            Expanded(
              child: Text(
                widget.entry.isDailyWage
                    ? '-'
                    : widget.entry.kva.toInt().toString(),
                style: AppTypography.tableCell,
              ),
            ),
            // Rate
            Expanded(
              child: Text(
                widget.entry.isDailyWage
                    ? '-'
                    : '₹${widget.entry.rate.toInt()}',
                style: AppTypography.tableCell,
              ),
            ),
            // Basic
            Expanded(
              child: Text(
                '₹${widget.entry.basicAmount.toInt()}',
                style: AppTypography.tableCell,
              ),
            ),
            // OT
            Expanded(
              child: widget.entry.ot > 0
                  ? TextBadge(
                      label: '+₹${widget.entry.otAmount.toInt()}',
                      backgroundColor: AppColors.infoSurface,
                      textColor: AppColors.infoDark,
                      isSmall: true,
                    )
                  : const Text('-'),
            ),
            // Total
            Expanded(
              child: Text(
                '₹${widget.entry.total.toInt()}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
            // Status
            Expanded(
              child: StatusBadge(
                label: 'Pending',
                type: StatusType.warning,
                isSmall: true,
              ),
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
                  AppIconButton(
                    icon: AppIcons.approve,
                    tooltip: 'Approve',
                    size: 28,
                    iconSize: 14,
                    color: AppColors.success,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactoryEntry {
  final String employeeId;
  final String name;
  final String department;
  final double hoursWorked;
  final double kva;
  final double rate;
  final double basicAmount;
  final double ot;
  final double otAmount;
  final double total;
  final bool isDailyWage;

  const _FactoryEntry({
    required this.employeeId,
    required this.name,
    required this.department,
    required this.hoursWorked,
    required this.kva,
    required this.rate,
    required this.basicAmount,
    required this.ot,
    required this.otAmount,
    required this.total,
    this.isDailyWage = false,
  });
}
