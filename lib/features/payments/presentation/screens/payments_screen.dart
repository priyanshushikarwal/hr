import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';

/// Payments Screen - Salary slip generation and payment tracking
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _currentTab = 'all';

  final List<_PaymentRecord> _payments = [
    _PaymentRecord(
      employeeId: 'EMP001',
      name: 'Rajesh Kumar',
      department: 'Engineering',
      type: 'office',
      grossSalary: 75000,
      deductions: 12500,
      netSalary: 62500,
      status: 'paid',
      paidDate: DateTime(2024, 1, 25),
    ),
    _PaymentRecord(
      employeeId: 'EMP002',
      name: 'Priya Sharma',
      department: 'Human Resources',
      type: 'office',
      grossSalary: 65000,
      deductions: 9800,
      netSalary: 55200,
      status: 'paid',
      paidDate: DateTime(2024, 1, 25),
    ),
    _PaymentRecord(
      employeeId: 'EMP003',
      name: 'Amit Patel',
      department: 'Production',
      type: 'factory',
      grossSalary: 28500,
      deductions: 4275,
      netSalary: 24225,
      status: 'pending',
    ),
    _PaymentRecord(
      employeeId: 'EMP004',
      name: 'Sneha Reddy',
      department: 'Finance',
      type: 'office',
      grossSalary: 55000,
      deductions: 8250,
      netSalary: 46750,
      status: 'processing',
    ),
    _PaymentRecord(
      employeeId: 'EMP005',
      name: 'Vikram Singh',
      department: 'Production',
      type: 'factory',
      grossSalary: 22000,
      deductions: 1650,
      netSalary: 20350,
      status: 'pending',
    ),
  ];

  List<_PaymentRecord> get _filteredPayments {
    if (_currentTab == 'all') return _payments;
    if (_currentTab == 'office')
      return _payments.where((p) => p.type == 'office').toList();
    if (_currentTab == 'factory')
      return _payments.where((p) => p.type == 'factory').toList();
    return _payments.where((p) => p.status == _currentTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Salary Slip & Payments',
            subtitle: 'Process salaries and generate salary slips',
            breadcrumbs: const ['Home', 'Payments'],
            actions: [
              SecondaryButton(
                text: 'Export Bank File',
                icon: AppIcons.bank,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Process Salary',
                icon: AppIcons.money,
                useGradient: true,
                onPressed: () => _showProcessSalaryDialog(context),
              ),
            ],
          ),

          // Month Selector and Stats
          _buildMonthHeader(),

          const SizedBox(height: AppSpacing.lg),

          // Summary Cards
          _buildSummaryCards(),

          const SizedBox(height: AppSpacing.lg),

          // Payments Table
          _buildPaymentsTable(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return ContentCard(
      child: Row(
        children: [
          // Month Picker
          Row(
            children: [
              AppIconButton(
                icon: AppIcons.chevronLeft,
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              Container(
                width: 200,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.calendar, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: AppTypography.titleSmall,
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: AppIcons.chevronRight,
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
          const Spacer(),

          // Quick Stats
          _QuickStat(
            label: 'Total Employees',
            value: _payments.length.toString(),
            color: AppColors.primary,
          ),
          const SizedBox(width: 24),
          _QuickStat(
            label: 'Processed',
            value: _payments.where((p) => p.status == 'paid').length.toString(),
            color: AppColors.success,
          ),
          const SizedBox(width: 24),
          _QuickStat(
            label: 'Pending',
            value: _payments
                .where((p) => p.status == 'pending')
                .length
                .toString(),
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalGross = _payments.fold<double>(
      0,
      (sum, p) => sum + p.grossSalary,
    );
    final totalDeductions = _payments.fold<double>(
      0,
      (sum, p) => sum + p.deductions,
    );
    final totalNet = _payments.fold<double>(0, (sum, p) => sum + p.netSalary);
    final paidAmount = _payments
        .where((p) => p.status == 'paid')
        .fold<double>(0, (sum, p) => sum + p.netSalary);

    return Row(
      children: [
        _SummaryCard(
          title: 'Total Gross',
          value: '₹${_formatNumber(totalGross.toInt())}',
          icon: AppIcons.chart,
          color: AppColors.primary,
          subtitle: 'Before deductions',
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Total Deductions',
          value: '₹${_formatNumber(totalDeductions.toInt())}',
          icon: AppIcons.trendDown,
          color: AppColors.error,
          subtitle: 'PF + ESIC + TDS + Others',
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Total Net Payable',
          value: '₹${_formatNumber(totalNet.toInt())}',
          icon: AppIcons.wallet,
          color: AppColors.info,
          subtitle: 'After deductions',
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Paid',
          value: '₹${_formatNumber(paidAmount.toInt())}',
          icon: AppIcons.check,
          color: AppColors.success,
          subtitle:
              '${_payments.where((p) => p.status == 'paid').length} employees',
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildPaymentsTable() {
    return ContentCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Tabs and Actions
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _TabChip('All', 'all', _payments.length),
                _TabChip(
                  'Office',
                  'office',
                  _payments.where((p) => p.type == 'office').length,
                ),
                _TabChip(
                  'Factory',
                  'factory',
                  _payments.where((p) => p.type == 'factory').length,
                ),
                _TabChip(
                  'Paid',
                  'paid',
                  _payments.where((p) => p.status == 'paid').length,
                ),
                _TabChip(
                  'Pending',
                  'pending',
                  _payments.where((p) => p.status == 'pending').length,
                ),
                const Spacer(),
                AppSearchField(hint: 'Search by name or ID...', width: 250),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.backgroundSecondary,
            child: Row(
              children: [
                _TableHeader('EMPLOYEE', flex: 2),
                _TableHeader('DEPARTMENT'),
                _TableHeader('TYPE'),
                _TableHeader('GROSS'),
                _TableHeader('DEDUCTIONS'),
                _TableHeader('NET PAYABLE'),
                _TableHeader('STATUS'),
                const SizedBox(width: 120),
              ],
            ),
          ),

          // Table Rows
          ...List.generate(_filteredPayments.length, (index) {
            return _PaymentRow(payment: _filteredPayments[index]);
          }),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _TabChip(String label, String tabId, int count) {
    final isActive = _currentTab == tabId;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProcessSalaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Salary'),
        content: const Text(
          'Salary processing dialog will be implemented here',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Process'),
          ),
        ],
      ),
    );
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

  String _formatNumber(int number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    }
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleLarge.copyWith(color: color)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                Text(title, style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppTypography.headlineSmall.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypography.caption),
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

class _PaymentRow extends StatefulWidget {
  final _PaymentRecord payment;

  const _PaymentRow({required this.payment});

  @override
  State<_PaymentRow> createState() => _PaymentRowState();
}

class _PaymentRowState extends State<_PaymentRow> {
  bool _isHovered = false;

  StatusType get _statusType {
    switch (widget.payment.status) {
      case 'paid':
        return StatusType.success;
      case 'pending':
        return StatusType.warning;
      case 'processing':
        return StatusType.info;
      default:
        return StatusType.neutral;
    }
  }

  String get _statusLabel {
    switch (widget.payment.status) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      default:
        return widget.payment.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  UserAvatar(name: widget.payment.name, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payment.name,
                        style: AppTypography.labelLarge,
                      ),
                      Text(
                        widget.payment.employeeId,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Department
            Expanded(
              child: Text(
                widget.payment.department,
                style: AppTypography.tableCell,
              ),
            ),
            // Type
            Expanded(
              child: EmployeeTypeBadge(
                type: widget.payment.type,
                isSmall: true,
              ),
            ),
            // Gross
            Expanded(
              child: Text(
                '₹${_formatNumber(widget.payment.grossSalary.toInt())}',
                style: AppTypography.tableCell,
              ),
            ),
            // Deductions
            Expanded(
              child: Text(
                '₹${_formatNumber(widget.payment.deductions.toInt())}',
                style: AppTypography.tableCell.copyWith(color: AppColors.error),
              ),
            ),
            // Net
            Expanded(
              child: Text(
                '₹${_formatNumber(widget.payment.netSalary.toInt())}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
            // Status
            Expanded(
              child: StatusBadge(
                label: _statusLabel,
                type: _statusType,
                isSmall: true,
              ),
            ),
            // Actions
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppIconButton(
                    icon: AppIcons.filePdf,
                    tooltip: 'View Salary Slip',
                    onPressed: () {},
                  ),
                  AppIconButton(
                    icon: AppIcons.download,
                    tooltip: 'Download',
                    onPressed: () {},
                  ),
                  if (widget.payment.status == 'pending')
                    AppIconButton(
                      icon: AppIcons.send,
                      tooltip: 'Process Payment',
                      color: AppColors.primary,
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _PaymentRecord {
  final String employeeId;
  final String name;
  final String department;
  final String type;
  final double grossSalary;
  final double deductions;
  final double netSalary;
  final String status;
  final DateTime? paidDate;

  const _PaymentRecord({
    required this.employeeId,
    required this.name,
    required this.department,
    required this.type,
    required this.grossSalary,
    required this.deductions,
    required this.netSalary,
    required this.status,
    this.paidDate,
  });
}
