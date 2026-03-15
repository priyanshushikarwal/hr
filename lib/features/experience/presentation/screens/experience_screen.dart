import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../shared/layouts/header.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../domain/providers/experience_providers.dart';
import '../../data/models/experience_model.dart';
import '../widgets/experience_dialog.dart';

class ExperienceScreen extends ConsumerStatefulWidget {
  const ExperienceScreen({super.key});

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  Employee? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeListProvider);
    final activeEmployees = employeesState.employees.where((e) => e.isActive).toList();

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Career History',
            subtitle: 'Professional experience and internal tenure tracking',
            breadcrumbs: const ['Home', 'Work Experience'],
            actions: [
              if (_selectedEmployee != null)
                PrimaryButton(
                  text: 'Add Past Experience',
                  icon: AppIcons.add,
                  onPressed: () => _showExperienceDialog(context, _selectedEmployee!.id),
                ),
            ],
          ),

          // Employee Selector
          _buildEmployeeSelector(activeEmployees),

          const SizedBox(height: AppSpacing.lg),

          if (_selectedEmployee == null)
            _buildEmptyState('Please select an employee to view career history')
          else ...[
            _buildSummarySection(),
            const SizedBox(height: AppSpacing.lg),
            _buildExperienceList(_selectedEmployee!.id),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final state = ref.watch(experienceProvider);
    
    // Calculate External Days
    int externalDays = 0;
    for (var exp in state.records) {
      final end = exp.isCurrent ? DateTime.now() : (exp.endDate ?? DateTime.now());
      externalDays += end.difference(exp.startDate).inDays;
    }

    // Total Days = External + Internal (Attendance based)
    final int totalDays = externalDays + state.internalDays;

    return Row(
      children: [
        _SummaryStatCard(
          title: 'Total Experience',
          value: _formatDays(totalDays),
          subtitle: 'Combined History',
          icon: AppIcons.experience,
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _SummaryStatCard(
          title: 'Internal Tenure',
          value: _formatDays(state.internalDays),
          subtitle: 'Active Working Days',
          icon: AppIcons.office,
          color: AppColors.success,
        ),
        const SizedBox(width: 16),
        _SummaryStatCard(
          title: 'Past Companies',
          value: _formatDays(externalDays),
          subtitle: '${state.records.length} Organizations',
          icon: AppIcons.history,
          color: AppColors.info,
        ),
      ],
    );
  }

  String _formatDays(int days) {
    if (days <= 0) return '0 Days';
    final years = days ~/ 365;
    final remainingDaysAfterYears = days % 365;
    final months = remainingDaysAfterYears ~/ 30;
    final remainingDays = remainingDaysAfterYears % 30;

    List<String> parts = [];
    if (years > 0) parts.add('$years Year${years > 1 ? 's' : ''}');
    if (months > 0) parts.add('$months Month${months > 1 ? 's' : ''}');
    if (parts.isEmpty || remainingDays > 0) parts.add('$remainingDays Day${remainingDays > 1 ? 's' : ''}');
    
    return parts.join(', ');
  }

  Widget _buildEmployeeSelector(List<Employee> employees) {
    return ContentCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: AppDropdownField<Employee>(
              label: 'Selected Employee',
              hint: 'Select an employee to see experience',
              value: _selectedEmployee,
              items: employees,
              itemLabel: (emp) => '${emp.employeeCode} - ${emp.fullName}',
              prefixIcon: AppIcons.user,
              onChanged: (val) {
                setState(() => _selectedEmployee = val);
                if (val != null) {
                  ref.read(experienceProvider.notifier).loadExperience(val.id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceList(String employeeId) {
    final state = ref.watch(experienceProvider);

    if (state.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Previous Employment Records', style: AppTypography.titleMedium),
            if (state.records.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showExperienceDialog(context, employeeId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Experience'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.records.isEmpty)
          ContentCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(AppIcons.history, size: 48, color: AppColors.textTertiary.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('No past experience records added.'),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    text: 'Add Professional History',
                    icon: AppIcons.add,
                    onPressed: () => _showExperienceDialog(context, employeeId),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.records.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final exp = state.records[index];
              return _ExperienceCard(
                experience: exp,
                onEdit: () => _showExperienceDialog(context, employeeId, initialExperience: exp),
                onDelete: () => _confirmDelete(exp.id),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return ContentCard(
      padding: const EdgeInsets.all(64),
      child: Center(
        child: Column(
          children: [
            Icon(AppIcons.experience, size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(message, style: AppTypography.bodyLarge.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  void _showExperienceDialog(BuildContext context, String employeeId, {WorkExperience? initialExperience}) {
    showDialog(
      context: context,
      builder: (context) => ExperienceDialog(
        employeeId: employeeId,
        initialExperience: initialExperience,
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Experience?'),
        content: const Text('Are you sure you want to remove this work experience record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(experienceProvider.notifier).deleteExperience(id);
    }
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ContentCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text(value, style: AppTypography.titleMedium.copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.labelSmall.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final WorkExperience experience;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExperienceCard({
    required this.experience,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateRange = '${DateFormat('MMM yyyy').format(experience.startDate)} - '
        '${experience.isCurrent ? 'Present' : (experience.endDate != null ? DateFormat('MMM yyyy').format(experience.endDate!) : 'N/A')}';

    return ContentCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(AppIcons.department, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(experience.designation, style: AppTypography.titleMedium),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
                Text(experience.companyName, style: AppTypography.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(AppIcons.calendar, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(dateRange, style: AppTypography.bodySmall),
                    if (experience.location != null) ...[
                      const SizedBox(width: 16),
                      Icon(AppIcons.location, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(experience.location!, style: AppTypography.bodySmall),
                    ],
                  ],
                ),
                if (experience.description != null) ...[
                  const SizedBox(height: 12),
                  Text(experience.description!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
