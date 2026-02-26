import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../core/widgets/buttons.dart';

/// Employee Filters Panel
class EmployeeFilters extends StatelessWidget {
  final String? selectedDepartment;
  final String? selectedEmployeeType;
  final String? selectedStatus;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onEmployeeTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClearFilters;

  const EmployeeFilters({
    super.key,
    this.selectedDepartment,
    this.selectedEmployeeType,
    this.selectedStatus,
    required this.onDepartmentChanged,
    required this.onEmployeeTypeChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
  });

  bool get hasFilters =>
      selectedDepartment != null ||
      selectedEmployeeType != null ||
      selectedStatus != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Department Filter
          Expanded(
            child: AppDropdownField<String>(
              hint: 'All Departments',
              value: selectedDepartment,
              items: AppConstants.departments,
              itemLabel: (item) => item,
              onChanged: onDepartmentChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Employee Type Filter
          Expanded(
            child: AppDropdownField<String>(
              hint: 'All Types',
              value: selectedEmployeeType,
              items: const ['office', 'factory'],
              itemLabel: (item) => item == 'office' ? 'Office' : 'Factory',
              onChanged: onEmployeeTypeChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Status Filter
          Expanded(
            child: AppDropdownField<String>(
              hint: 'All Status',
              value: selectedStatus,
              items: const ['active', 'inactive', 'on_leave'],
              itemLabel: (item) {
                switch (item) {
                  case 'active':
                    return 'Active';
                  case 'inactive':
                    return 'Inactive';
                  case 'on_leave':
                    return 'On Leave';
                  default:
                    return item;
                }
              },
              onChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Clear Filters
          if (hasFilters)
            GhostButton(
              text: 'Clear Filters',
              color: AppColors.error,
              onPressed: onClearFilters,
            ),
        ],
      ),
    );
  }
}
