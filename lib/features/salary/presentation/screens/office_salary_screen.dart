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

/// Office Salary Screen - Manage salary structure for office employees
class OfficeSalaryScreen extends StatefulWidget {
  const OfficeSalaryScreen({super.key});

  @override
  State<OfficeSalaryScreen> createState() => _OfficeSalaryScreenState();
}

class _OfficeSalaryScreenState extends State<OfficeSalaryScreen> {
  String? _selectedEmployee;
  bool _showEditMode = false;

  @override
  Widget build(BuildContext context) {
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
                text: 'Export All',
                icon: AppIcons.export,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Bulk Update',
                icon: AppIcons.edit,
                onPressed: () {},
              ),
            ],
          ),

          // Employee Selector
          _buildEmployeeSelector(),

          const SizedBox(height: AppSpacing.lg),

          // Salary Structure View
          if (_selectedEmployee != null) ...[
            _buildSalarySummary(),
            const SizedBox(height: AppSpacing.lg),
            _buildSalaryBreakdown(),
          ] else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    return ContentCard(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppDropdownField<String>(
              label: 'Select Employee',
              hint: 'Search and select an office employee',
              value: _selectedEmployee,
              items: const [
                'EMP001 - Rajesh Kumar (Senior Engineer)',
                'EMP002 - Priya Sharma (HR Manager)',
                'EMP004 - Sneha Reddy (Senior Accountant)',
                'EMP006 - Neha Gupta (Marketing Executive)',
              ],
              itemLabel: (item) => item,
              onChanged: (value) => setState(() => _selectedEmployee = value),
              prefixIcon: AppIcons.employees,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          if (_selectedEmployee != null) ...[
            SecondaryButton(
              text: 'View History',
              icon: AppIcons.history,
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            PrimaryButton(
              text: _showEditMode ? 'Cancel' : 'Edit Structure',
              icon: _showEditMode ? AppIcons.close : AppIcons.edit,
              onPressed: () => setState(() => _showEditMode = !_showEditMode),
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

  Widget _buildSalarySummary() {
    return Row(
      children: [
        _SalarySummaryCard(
          title: 'Gross Salary',
          value: '₹75,000',
          icon: AppIcons.money,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _SalarySummaryCard(
          title: 'Total Deductions',
          value: '₹12,500',
          icon: AppIcons.trendDown,
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.md),
        _SalarySummaryCard(
          title: 'Net Salary',
          value: '₹62,500',
          icon: AppIcons.wallet,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _SalarySummaryCard(
          title: 'CTC (Annual)',
          value: '₹10.8 L',
          icon: AppIcons.chart,
          color: AppColors.info,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSalaryBreakdown() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Earnings
        Expanded(
          child: ContentCard(
            title: 'Earnings',
            titleAction: TextBadge(
              label: '₹75,000/month',
              backgroundColor: AppColors.successSurface,
              textColor: AppColors.successDark,
            ),
            child: Column(
              children: [
                _SalaryRow(
                  label: 'Basic Salary',
                  value: 30000,
                  percentage: 40,
                  isEditable: _showEditMode,
                ),
                _SalaryRow(
                  label: 'House Rent Allowance (HRA)',
                  value: 15000,
                  percentage: 20,
                  isEditable: _showEditMode,
                ),
                _SalaryRow(
                  label: 'Dearness Allowance (DA)',
                  value: 10000,
                  percentage: 13.3,
                  isEditable: _showEditMode,
                ),
                _SalaryRow(
                  label: 'Conveyance Allowance',
                  value: 5000,
                  isEditable: _showEditMode,
                ),
                _SalaryRow(
                  label: 'Medical Allowance',
                  value: 5000,
                  isEditable: _showEditMode,
                ),
                _SalaryRow(
                  label: 'Special Allowance',
                  value: 10000,
                  isEditable: _showEditMode,
                ),
                const Divider(height: 32),
                _SalaryRow(
                  label: 'Total Earnings',
                  value: 75000,
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
              label: '₹12,500/month',
              backgroundColor: AppColors.errorSurface,
              textColor: AppColors.errorDark,
            ),
            child: Column(
              children: [
                _SalaryRow(
                  label: 'Provident Fund (PF)',
                  value: 3600,
                  subtitle: '12% of Basic',
                  isDeduction: true,
                  showStatus: true,
                  statusActive: true,
                ),
                _SalaryRow(
                  label: 'ESIC',
                  value: 0,
                  subtitle: 'Not Applicable (Gross > 21K)',
                  isDeduction: true,
                  showStatus: true,
                  statusActive: false,
                ),
                _SalaryRow(
                  label: 'Professional Tax',
                  value: 200,
                  isDeduction: true,
                ),
                _SalaryRow(
                  label: 'TDS',
                  value: 8700,
                  subtitle: 'As per tax slab',
                  isDeduction: true,
                ),
                _SalaryRow(label: 'Loan EMI', value: 0, isDeduction: true),
                _SalaryRow(
                  label: 'Advance Recovery',
                  value: 0,
                  isDeduction: true,
                ),
                const Divider(height: 32),
                _SalaryRow(
                  label: 'Total Deductions',
                  value: 12500,
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
  final bool isEditable;
  final bool showStatus;
  final bool statusActive;

  const _SalaryRow({
    required this.label,
    required this.value,
    this.percentage,
    this.subtitle,
    this.isDeduction = false,
    this.isTotal = false,
    this.isEditable = false,
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
            child: isEditable
                ? SizedBox(
                    height: 36,
                    child: TextField(
                      textAlign: TextAlign.right,
                      style: AppTypography.labelLarge,
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
                      controller: TextEditingController(
                        text: value.toInt().toString(),
                      ),
                    ),
                  )
                : Text(
                    '₹${_formatNumber(value.toInt())}',
                    style: isTotal
                        ? AppTypography.titleMedium.copyWith(
                            color: isDeduction
                                ? AppColors.error
                                : AppColors.success,
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
