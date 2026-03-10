import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';

import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../data/models/salary_models.dart';
import '../../domain/providers/salary_providers.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../widgets/generate_salary_slip_dialog.dart';

/// Office Salary Screen - Manage salary structure for office employees
class OfficeSalaryScreen extends ConsumerStatefulWidget {
  const OfficeSalaryScreen({super.key});

  @override
  ConsumerState<OfficeSalaryScreen> createState() => _OfficeSalaryScreenState();
}

class _OfficeSalaryScreenState extends ConsumerState<OfficeSalaryScreen> {
  Employee? _selectedEmployee;
  bool _showEditMode = false;

  // Edit controllers
  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _daController = TextEditingController(text: '0');
  final _conveyanceController = TextEditingController(text: '0');
  final _medicalController = TextEditingController(text: '0');
  final _specialController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  bool _pfApplicable = false;
  bool _esicApplicable = false;

  @override
  void dispose() {
    _basicController.dispose();
    _hraController.dispose();
    _daController.dispose();
    _conveyanceController.dispose();
    _medicalController.dispose();
    _specialController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _populateFromSalary(OfficeSalaryStructure salary) {
    _basicController.text = salary.basicSalary.toInt().toString();
    _hraController.text = salary.hra.toInt().toString();
    _daController.text = salary.da.toInt().toString();
    _conveyanceController.text = salary.conveyanceAllowance.toInt().toString();
    _medicalController.text = salary.medicalAllowance.toInt().toString();
    _specialController.text = salary.specialAllowance.toInt().toString();
    _otherController.text = salary.otherAllowances.toInt().toString();
    _pfApplicable = salary.isPfApplicable;
    _esicApplicable = salary.isEsicApplicable;
  }

  double get _editBasic => double.tryParse(_basicController.text) ?? 0;
  double get _editHra => double.tryParse(_hraController.text) ?? 0;
  double get _editDa => double.tryParse(_daController.text) ?? 0;
  double get _editConv => double.tryParse(_conveyanceController.text) ?? 0;
  double get _editMed => double.tryParse(_medicalController.text) ?? 0;
  double get _editSpecial => double.tryParse(_specialController.text) ?? 0;
  double get _editOther => double.tryParse(_otherController.text) ?? 0;
  double get _editGross =>
      _editBasic +
      _editHra +
      _editDa +
      _editConv +
      _editMed +
      _editSpecial +
      _editOther;
  double get _editPfEmp =>
      _pfApplicable ? OfficeSalaryStructure.calculatePfEmployee(_editBasic) : 0;
  double get _editPfEmployer =>
      _pfApplicable ? OfficeSalaryStructure.calculatePfEmployer(_editBasic) : 0;
  double get _editEsicEmp => _esicApplicable
      ? OfficeSalaryStructure.calculateEsicEmployee(_editGross)
      : 0;
  double get _editEsicEmployer => _esicApplicable
      ? OfficeSalaryStructure.calculateEsicEmployer(_editGross)
      : 0;
  double get _editTotalDed => _editPfEmp + _editEsicEmp;
  double get _editNet => _editGross - _editTotalDed;
  double get _editCtc => _editGross + _editPfEmployer + _editEsicEmployer;

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(officeSalaryProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Office Employee Salary',
            subtitle: 'Configure salary structure and components',
            breadcrumbs: const ['Home', 'Salary Structure', 'Office'],
            actions: [
              SecondaryButton(
                text: 'Generate Salary Slip',
                icon: AppIcons.download,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => GenerateSalarySlipDialog(
                      preselectedEmployee: _selectedEmployee,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Save Structure',
                icon: AppIcons.check,
                onPressed: _showEditMode && _selectedEmployee != null
                    ? _saveSalary
                    : null,
              ),
            ],
          ),

          // Employee Selector
          _buildEmployeeSelector(),

          const SizedBox(height: AppSpacing.lg),

          // Loading state
          if (salaryState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_selectedEmployee != null) ...[
            _buildSalarySummary(salaryState.salary),
            const SizedBox(height: AppSpacing.lg),
            _buildSalaryBreakdown(salaryState.salary),
          ] else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    final employeesState = ref.watch(employeeListProvider);
    final activeOfficeEmployees = employeesState.employees
        .where((e) => e.isActive && e.isOffice)
        .toList();

    return ContentCard(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedEmployee?.id,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Select Employee',
                hintText: 'Choose an office employee',
                prefixIcon: const Icon(AppIcons.employees, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: activeOfficeEmployees.map((emp) {
                return DropdownMenuItem(
                  value: emp.id,
                  child: Text(
                    '${emp.employeeCode} - ${emp.fullName} (${emp.designation})',
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (empId) {
                if (empId == null) return;
                final emp = activeOfficeEmployees.firstWhere(
                  (e) => e.id == empId,
                );
                setState(() {
                  _selectedEmployee = emp;
                  _showEditMode = false;
                });
                // Load salary for this employee
                ref.read(officeSalaryProvider.notifier).loadSalary(emp.id);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          if (_selectedEmployee != null) ...[
            SecondaryButton(
              text: 'Salary Slip',
              icon: AppIcons.download,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => GenerateSalarySlipDialog(
                    preselectedEmployee: _selectedEmployee,
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            PrimaryButton(
              text: _showEditMode ? 'Cancel' : 'Edit Structure',
              icon: _showEditMode ? AppIcons.close : AppIcons.edit,
              onPressed: () {
                final salary = ref.read(officeSalaryProvider).salary;
                if (!_showEditMode && salary != null) {
                  _populateFromSalary(salary);
                }
                setState(() => _showEditMode = !_showEditMode);
              },
            ),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmptyState() {
    return ContentCard(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.salary, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Select an Employee',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose an employee from the dropdown to view or edit their salary structure',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalarySummary(OfficeSalaryStructure? salary) {
    final gross = _showEditMode ? _editGross : (salary?.grossSalary ?? 0);
    final ded = _showEditMode ? _editTotalDed : (salary?.totalDeductions ?? 0);
    final net = _showEditMode ? _editNet : (salary?.netSalary ?? 0);
    final ctc = _showEditMode ? _editCtc : (salary?.ctc ?? 0);

    return Row(
      children: [
        _SalarySummaryCard(
          title: 'Gross Salary',
          value: '₹${_formatNum(gross.toInt())}',
          icon: AppIcons.money,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _SalarySummaryCard(
          title: 'Total Deductions',
          value: '₹${_formatNum(ded.toInt())}',
          icon: AppIcons.trendDown,
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.md),
        _SalarySummaryCard(
          title: 'Net Salary',
          value: '₹${_formatNum(net.toInt())}',
          icon: AppIcons.wallet,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _SalarySummaryCard(
          title: 'CTC (Annual)',
          value: '₹${_formatNum((ctc * 12).toInt())}',
          icon: AppIcons.chart,
          color: AppColors.info,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSalaryBreakdown(OfficeSalaryStructure? salary) {
    final hasSalary = salary != null;

    if (_showEditMode) {
      return _buildEditableBreakdown(salary);
    }

    if (!hasSalary) {
      return ContentCard(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.salary, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'No salary structure found for this employee',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Create Salary Structure',
                icon: AppIcons.add,
                onPressed: () {
                  // Pre-fill with zeros and enter edit mode
                  _basicController.text = '0';
                  _hraController.text = '0';
                  _daController.text = '0';
                  _conveyanceController.text = '0';
                  _medicalController.text = '0';
                  _specialController.text = '0';
                  _otherController.text = '0';
                  _pfApplicable = _selectedEmployee?.isPfApplicable ?? false;
                  _esicApplicable =
                      _selectedEmployee?.isEsicApplicable ?? false;
                  setState(() => _showEditMode = true);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Earnings
        Expanded(
          child: ContentCard(
            title: 'Earnings',
            titleAction: TextBadge(
              label: '₹${_formatNum(salary.grossSalary.toInt())}/month',
              backgroundColor: AppColors.successSurface,
              textColor: AppColors.successDark,
            ),
            child: Column(
              children: [
                _SalaryRow(
                  label: 'Basic Salary',
                  value: salary.basicSalary,
                  percentage: salary.grossSalary > 0
                      ? salary.basicSalary / salary.grossSalary * 100
                      : 0,
                ),
                _SalaryRow(
                  label: 'House Rent Allowance (HRA)',
                  value: salary.hra,
                  percentage: salary.grossSalary > 0
                      ? salary.hra / salary.grossSalary * 100
                      : 0,
                ),
                _SalaryRow(label: 'Dearness Allowance (DA)', value: salary.da),
                _SalaryRow(
                  label: 'Conveyance Allowance',
                  value: salary.conveyanceAllowance,
                ),
                _SalaryRow(
                  label: 'Medical Allowance',
                  value: salary.medicalAllowance,
                ),
                _SalaryRow(
                  label: 'Special Allowance',
                  value: salary.specialAllowance,
                ),
                _SalaryRow(
                  label: 'Other Allowances',
                  value: salary.otherAllowances,
                ),
                const Divider(height: 32),
                _SalaryRow(
                  label: 'Total Earnings',
                  value: salary.grossSalary,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideX(begin: -0.05, end: 0),

        const SizedBox(width: AppSpacing.lg),

        // Deductions
        Expanded(
          child: ContentCard(
            title: 'Deductions',
            titleAction: TextBadge(
              label: '₹${_formatNum(salary.totalDeductions.toInt())}/month',
              backgroundColor: AppColors.errorSurface,
              textColor: AppColors.errorDark,
            ),
            child: Column(
              children: [
                _SalaryRow(
                  label: 'Provident Fund (PF)',
                  value: salary.pfEmployee,
                  subtitle: '12% of Basic',
                  isDeduction: true,
                  showStatus: true,
                  statusActive: salary.isPfApplicable,
                ),
                _SalaryRow(
                  label: 'ESIC',
                  value: salary.esicEmployee,
                  subtitle: salary.isEsicApplicable
                      ? '0.75% of Gross'
                      : 'Not Applicable',
                  isDeduction: true,
                  showStatus: true,
                  statusActive: salary.isEsicApplicable,
                ),
                _SalaryRow(
                  label: 'Professional Tax',
                  value: salary.professionalTax,
                  isDeduction: true,
                ),
                _SalaryRow(
                  label: 'TDS',
                  value: salary.tds,
                  subtitle: 'As per tax slab',
                  isDeduction: true,
                ),
                _SalaryRow(
                  label: 'Other Deductions',
                  value: salary.otherDeductions,
                  isDeduction: true,
                ),
                const Divider(height: 32),
                _SalaryRow(
                  label: 'Total Deductions',
                  value: salary.totalDeductions,
                  isTotal: true,
                  isDeduction: true,
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideX(begin: 0.05, end: 0),
      ],
    );
  }

  Widget _buildEditableBreakdown(OfficeSalaryStructure? salary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Earnings (editable)
        Expanded(
          child: ContentCard(
            title: 'Earnings',
            titleAction: TextBadge(
              label: '₹${_formatNum(_editGross.toInt())}/month',
              backgroundColor: AppColors.successSurface,
              textColor: AppColors.successDark,
            ),
            child: Column(
              children: [
                _EditField(
                  label: 'Basic Salary',
                  controller: _basicController,
                  onChanged: () => setState(() {}),
                ),
                _EditField(
                  label: 'HRA',
                  controller: _hraController,
                  onChanged: () => setState(() {}),
                ),
                _EditField(
                  label: 'Dearness Allowance (DA)',
                  controller: _daController,
                  onChanged: () => setState(() {}),
                ),
                _EditField(
                  label: 'Conveyance Allowance',
                  controller: _conveyanceController,
                  onChanged: () => setState(() {}),
                ),
                _EditField(
                  label: 'Medical Allowance',
                  controller: _medicalController,
                  onChanged: () => setState(() {}),
                ),
                _EditField(
                  label: 'Special Allowance',
                  controller: _specialController,
                  onChanged: () => setState(() {}),
                ),
                _EditField(
                  label: 'Other Allowances',
                  controller: _otherController,
                  onChanged: () => setState(() {}),
                ),
                const Divider(height: 24),
                _SalaryRow(
                  label: 'Total Earnings',
                  value: _editGross,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),

        // Deductions (computed)
        Expanded(
          child: ContentCard(
            title: 'Deductions (Auto-calculated)',
            titleAction: TextBadge(
              label: '₹${_formatNum(_editTotalDed.toInt())}/month',
              backgroundColor: AppColors.errorSurface,
              textColor: AppColors.errorDark,
            ),
            child: Column(
              children: [
                // PF toggle
                _ToggleRow(
                  label: 'PF Applicable',
                  value: _pfApplicable,
                  onChanged: (v) => setState(() => _pfApplicable = v),
                ),
                _SalaryRow(
                  label: 'PF Employee (12%)',
                  value: _editPfEmp,
                  isDeduction: true,
                  showStatus: true,
                  statusActive: _pfApplicable,
                ),
                _SalaryRow(
                  label: 'PF Employer (12%)',
                  value: _editPfEmployer,
                  isDeduction: true,
                  subtitle: 'Part of CTC',
                ),
                const SizedBox(height: 8),

                // ESIC toggle
                _ToggleRow(
                  label: 'ESIC Applicable',
                  value: _esicApplicable,
                  onChanged: (v) => setState(() => _esicApplicable = v),
                ),
                _SalaryRow(
                  label: 'ESIC Employee (0.75%)',
                  value: _editEsicEmp,
                  isDeduction: true,
                  showStatus: true,
                  statusActive: _esicApplicable,
                ),
                _SalaryRow(
                  label: 'ESIC Employer (3.25%)',
                  value: _editEsicEmployer,
                  isDeduction: true,
                  subtitle: 'Part of CTC',
                ),
                const Divider(height: 24),
                _SalaryRow(
                  label: 'Total Deductions',
                  value: _editTotalDed,
                  isTotal: true,
                  isDeduction: true,
                ),
                const SizedBox(height: 8),
                _SalaryRow(label: 'Net Salary', value: _editNet, isTotal: true),
                const SizedBox(height: 4),
                _SalaryRow(
                  label: 'CTC (Monthly)',
                  value: _editCtc,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSalary() async {
    if (_selectedEmployee == null) return;
    // show loading state is handled by provider's isSaving

    try {
      final existingSalary = ref.read(officeSalaryProvider).salary;
      final user = ref.read(currentUserProvider);
      final now = DateTime.now();

      final salary = OfficeSalaryStructure(
        id: existingSalary?.id ?? '',
        employeeId: _selectedEmployee!.id,
        employeeCode: _selectedEmployee!.employeeCode,
        effectiveFrom: existingSalary?.effectiveFrom ?? now,
        basicSalary: _editBasic,
        hra: _editHra,
        da: _editDa,
        conveyanceAllowance: _editConv,
        medicalAllowance: _editMed,
        specialAllowance: _editSpecial,
        otherAllowances: _editOther,
        grossSalary: _editGross,
        pfEmployee: _editPfEmp,
        pfEmployer: _editPfEmployer,
        esicEmployee: _editEsicEmp,
        esicEmployer: _editEsicEmployer,
        isPfApplicable: _pfApplicable,
        isEsicApplicable: _esicApplicable,
        totalDeductions: _editTotalDed,
        netSalary: _editNet,
        ctc: _editCtc,
        createdAt: existingSalary?.createdAt ?? now,
        updatedAt: now,
        createdBy: user?.userId ?? 'hr',
        status: 'active',
      );

      await ref.read(officeSalaryProvider.notifier).saveSalary(salary);

      if (mounted) {
        setState(() {
          _showEditMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salary structure saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // error handled by snackbar below
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatNum(int number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    }
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _SalarySummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SalarySummaryCard({
    required this.title,
    required this.value,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.headlineSmall.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalaryRow extends StatelessWidget {
  final String label;
  final double value;
  final double? percentage;
  final String? subtitle;
  final bool isDeduction;
  final bool isTotal;
  final bool showStatus;
  final bool statusActive;

  const _SalaryRow({
    required this.label,
    required this.value,
    this.percentage,
    this.subtitle,
    this.isDeduction = false,
    this.isTotal = false,
    this.showStatus = false,
    this.statusActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: isTotal
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: isTotal
                          ? AppTypography.titleSmall
                          : AppTypography.bodyMedium,
                    ),
                    if (showStatus) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusActive
                              ? AppColors.successSurface
                              : AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusActive ? 'Active' : 'N/A',
                          style: AppTypography.labelSmall.copyWith(
                            color: statusActive
                                ? AppColors.successDark
                                : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
          if (percentage != null)
            SizedBox(
              width: 60,
              child: Text(
                '${percentage!.toStringAsFixed(1)}%',
                style: AppTypography.caption,
                textAlign: TextAlign.right,
              ),
            ),
          SizedBox(
            width: 120,
            child: Text(
              '₹${_formatNumber(value.toInt())}',
              style: isTotal
                  ? AppTypography.titleMedium.copyWith(
                      color: isDeduction ? AppColors.error : AppColors.success,
                    )
                  : AppTypography.labelLarge.copyWith(
                      color: isDeduction
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return number.toString();
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _EditField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          SizedBox(
            width: 140,
            height: 36,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: AppTypography.labelLarge,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixText: '₹',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: AppTypography.labelMedium),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
