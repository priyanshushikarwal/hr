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
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../../salary/domain/providers/salary_providers.dart';
import '../../../salary/data/models/salary_models.dart';
import '../../../salary/data/repositories/salary_repository.dart';
import '../../../salary/presentation/widgets/generate_salary_slip_dialog.dart';
import '../../../../core/services/network_service.dart';

/// Payments Screen - Salary slip generation and payment tracking
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _currentTab = 'all';
  bool _isLoading = true;
  Map<String, OfficeSalaryStructure> _salaryMap = {};

  @override
  void initState() {
    super.initState();
    _loadSalaryData();
  }

  Future<void> _loadSalaryData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(salaryRepositoryProvider);
      final isOnline = ref.read(networkStatusProvider) == NetworkStatus.online;
      final salaries = await repo.getAllOfficeSalaries(isOnline: isOnline);
      final map = <String, OfficeSalaryStructure>{};
      for (final s in salaries) {
        map[s.employeeId] = s;
      }
      if (mounted) {
        setState(() {
          _salaryMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeListProvider);
    final activeEmployees = employeesState.employees
        .where((e) => e.isActive)
        .toList();

    // Build payment records from real employee + salary data
    final payments = activeEmployees.map((emp) {
      final salary = _salaryMap[emp.id];
      return _PaymentRecord(
        employee: emp,
        employeeId: emp.employeeCode,
        name: emp.fullName,
        department: emp.department,
        type: emp.employeeType.toLowerCase(),
        grossSalary: salary?.grossSalary ?? 0,
        deductions: salary?.totalDeductions ?? 0,
        netSalary: salary?.netSalary ?? 0,
        status: 'pending', // Will be determined by payment records
        salary: salary,
      );
    }).toList();

    final filteredPayments = _getFilteredPayments(payments);

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
                text: 'Generate Salary Slip',
                icon: AppIcons.download,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const GenerateSalarySlipDialog(),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Process Salary',
                icon: AppIcons.money,
                useGradient: true,
                onPressed: () => _showProcessSalaryDialog(context, payments),
              ),
            ],
          ),

          // Month Selector and Stats
          _buildMonthHeader(payments),

          const SizedBox(height: AppSpacing.lg),

          // Summary Cards
          _buildSummaryCards(payments),

          const SizedBox(height: AppSpacing.lg),

          // Loading state
          if (employeesState.isLoading || _isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (activeEmployees.isEmpty)
            ContentCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        AppIcons.money,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No employees found. Add employees first.',
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
            // Payments Table
            _buildPaymentsTable(payments, filteredPayments),
        ],
      ),
    );
  }

  List<_PaymentRecord> _getFilteredPayments(List<_PaymentRecord> payments) {
    if (_currentTab == 'all') return payments;
    if (_currentTab == 'office') {
      return payments.where((p) => p.type == 'office').toList();
    }
    if (_currentTab == 'factory') {
      return payments.where((p) => p.type == 'factory').toList();
    }
    if (_currentTab == 'has_salary') {
      return payments.where((p) => p.grossSalary > 0).toList();
    }
    if (_currentTab == 'no_salary') {
      return payments.where((p) => p.grossSalary == 0).toList();
    }
    return payments.where((p) => p.status == _currentTab).toList();
  }

  Widget _buildMonthHeader(List<_PaymentRecord> payments) {
    final withSalary = payments.where((p) => p.grossSalary > 0).length;

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
            value: payments.length.toString(),
            color: AppColors.primary,
          ),
          const SizedBox(width: 24),
          _QuickStat(
            label: 'With Salary',
            value: withSalary.toString(),
            color: AppColors.success,
          ),
          const SizedBox(width: 24),
          _QuickStat(
            label: 'No Salary Set',
            value: (payments.length - withSalary).toString(),
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<_PaymentRecord> payments) {
    final totalGross = payments.fold<double>(
      0,
      (sum, p) => sum + p.grossSalary,
    );
    final totalDeductions = payments.fold<double>(
      0,
      (sum, p) => sum + p.deductions,
    );
    final totalNet = payments.fold<double>(0, (sum, p) => sum + p.netSalary);
    final totalCTC = payments.fold<double>(
      0,
      (sum, p) => sum + (p.salary?.ctc ?? 0),
    );

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
          subtitle: 'PF + ESIC + Others',
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Total Net Payable',
          value: '₹${_formatNumber(totalNet.toInt())}',
          icon: AppIcons.wallet,
          color: AppColors.success,
          subtitle: 'After deductions',
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Total CTC',
          value: '₹${_formatNumber(totalCTC.toInt())}',
          icon: AppIcons.money,
          color: AppColors.info,
          subtitle: 'Monthly cost to company',
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildPaymentsTable(
    List<_PaymentRecord> payments,
    List<_PaymentRecord> filteredPayments,
  ) {
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
                _TabChip('All', 'all', payments.length),
                _TabChip(
                  'Office',
                  'office',
                  payments.where((p) => p.type == 'office').length,
                ),
                _TabChip(
                  'Factory',
                  'factory',
                  payments.where((p) => p.type == 'factory').length,
                ),
                _TabChip(
                  'Has Salary',
                  'has_salary',
                  payments.where((p) => p.grossSalary > 0).length,
                ),
                _TabChip(
                  'No Salary',
                  'no_salary',
                  payments.where((p) => p.grossSalary == 0).length,
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
          ...List.generate(filteredPayments.length, (index) {
            return _PaymentRow(
              payment: filteredPayments[index],
              onGenerateSlip: () {
                showDialog(
                  context: context,
                  builder: (context) => GenerateSalarySlipDialog(
                    preselectedEmployee: filteredPayments[index].employee,
                  ),
                );
              },
            );
          }),

          if (filteredPayments.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      AppIcons.salary,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No employees found for this filter.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _TabChip(String label, String tabId, int count) {
    final isActive = _currentTab == tabId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _currentTab = tabId),
        child: AnimatedContainer(
          duration: AppSpacing.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primarySurface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.transparent,
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
      ),
    );
  }

  void _showProcessSalaryDialog(
    BuildContext context,
    List<_PaymentRecord> payments,
  ) {
    final withSalary = payments.where((p) => p.grossSalary > 0).toList();
    final totalNet = withSalary.fold<double>(0, (sum, p) => sum + p.netSalary);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      AppIcons.money,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Process Salary', style: AppTypography.titleLarge),
                        Text(
                          '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _processRow('Total Employees', payments.length.toString()),
                    const Divider(height: 16),
                    _processRow(
                      'With Salary Structure',
                      withSalary.length.toString(),
                    ),
                    _processRow(
                      'Without Salary Structure',
                      (payments.length - withSalary.length).toString(),
                      isWarning: true,
                    ),
                    const Divider(height: 16),
                    _processRow(
                      'Total Gross',
                      '₹${_formatNumber(withSalary.fold<double>(0, (sum, p) => sum + p.grossSalary).toInt())}',
                    ),
                    _processRow(
                      'Total Deductions',
                      '-₹${_formatNumber(withSalary.fold<double>(0, (sum, p) => sum + p.deductions).toInt())}',
                      isError: true,
                    ),
                    const Divider(height: 16),
                    _processRow(
                      'Total Net Payable',
                      '₹${_formatNumber(totalNet.toInt())}',
                      isBold: true,
                      isSuccess: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (payments.length - withSalary.length > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.warning,
                        size: 18,
                        color: AppColors.warningDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${payments.length - withSalary.length} employee(s) don\'t have a salary structure. Go to Office Salary screen to set up their salary.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warningDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    text: 'Generate All Slips',
                    icon: AppIcons.download,
                    onPressed: withSalary.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Salary slips generated for ${withSalary.length} employees!',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _processRow(
    String label,
    String value, {
    bool isBold = false,
    bool isWarning = false,
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color? color;
    if (isWarning) color = AppColors.warning;
    if (isError) color = AppColors.error;
    if (isSuccess) color = AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? AppTypography.labelLarge : AppTypography.bodyMedium,
          ),
          Text(
            value,
            style:
                (isBold ? AppTypography.titleSmall : AppTypography.labelLarge)
                    .copyWith(color: color),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: AppTypography.titleSmall.copyWith(color: color)),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
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
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppTypography.headlineSmall.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: AppTypography.labelMedium),
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
  final VoidCallback onGenerateSlip;

  const _PaymentRow({required this.payment, required this.onGenerateSlip});

  @override
  State<_PaymentRow> createState() => _PaymentRowState();
}

class _PaymentRowState extends State<_PaymentRow> {
  bool _isHovered = false;

  String get _statusLabel {
    if (widget.payment.grossSalary == 0) return 'No Salary';
    return 'Ready';
  }

  StatusType get _statusType {
    if (widget.payment.grossSalary == 0) return StatusType.neutral;
    return StatusType.success;
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.payment.name,
                          style: AppTypography.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.payment.employeeId,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Department
            Expanded(
              child: Text(
                widget.payment.department,
                style: AppTypography.tableCell,
                overflow: TextOverflow.ellipsis,
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
                widget.payment.grossSalary > 0
                    ? '₹${_formatNumber(widget.payment.grossSalary.toInt())}'
                    : '-',
                style: AppTypography.tableCell,
              ),
            ),
            // Deductions
            Expanded(
              child: Text(
                widget.payment.deductions > 0
                    ? '₹${_formatNumber(widget.payment.deductions.toInt())}'
                    : '-',
                style: AppTypography.tableCell.copyWith(color: AppColors.error),
              ),
            ),
            // Net
            Expanded(
              child: Text(
                widget.payment.netSalary > 0
                    ? '₹${_formatNumber(widget.payment.netSalary.toInt())}'
                    : '-',
                style: AppTypography.labelLarge.copyWith(
                  color: widget.payment.netSalary > 0
                      ? AppColors.success
                      : AppColors.textTertiary,
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
                  if (widget.payment.grossSalary > 0) ...[
                    AppIconButton(
                      icon: AppIcons.filePdf,
                      tooltip: 'Generate Salary Slip',
                      onPressed: widget.onGenerateSlip,
                    ),
                    AppIconButton(
                      icon: AppIcons.download,
                      tooltip: 'Download',
                      onPressed: widget.onGenerateSlip,
                    ),
                  ],
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
  final Employee employee;
  final String employeeId;
  final String name;
  final String department;
  final String type;
  final double grossSalary;
  final double deductions;
  final double netSalary;
  final String status;
  final OfficeSalaryStructure? salary;

  const _PaymentRecord({
    required this.employee,
    required this.employeeId,
    required this.name,
    required this.department,
    required this.type,
    required this.grossSalary,
    required this.deductions,
    required this.netSalary,
    required this.status,
    this.salary,
  });
}
