import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../data/models/attendance_models.dart';
import '../../domain/providers/attendance_providers.dart';
import '../../../auth/domain/providers/auth_providers.dart';

/// Mark Attendance Dialog
/// Used by HR to mark attendance for employees
class MarkAttendanceDialog extends ConsumerStatefulWidget {
  final List<Employee> employees;

  const MarkAttendanceDialog({super.key, required this.employees});

  @override
  ConsumerState<MarkAttendanceDialog> createState() =>
      _MarkAttendanceDialogState();
}

class _MarkAttendanceDialogState extends ConsumerState<MarkAttendanceDialog> {
  Employee? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'present';
  final _remarksController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'value': 'present',
      'label': 'Present',
      'icon': AppIcons.active,
      'color': AppColors.success,
    },
    {
      'value': 'absent',
      'label': 'Absent',
      'icon': AppIcons.xCircle,
      'color': AppColors.error,
    },
    {
      'value': 'half_day',
      'label': 'Half Day',
      'icon': AppIcons.clock,
      'color': AppColors.warning,
    },
    {
      'value': 'leave',
      'label': 'Leave',
      'icon': AppIcons.calendar,
      'color': AppColors.info,
    },
    {
      'value': 'visit',
      'label': 'Visit',
      'icon': AppIcons.location,
      'color': AppColors.secondary,
    },
  ];

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
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
                    AppIcons.attendance,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mark Attendance', style: AppTypography.titleLarge),
                      Text(
                        'Record employee attendance for a specific date',
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
            const Divider(),
            const SizedBox(height: 20),

            // Employee Selector
            Text('Employee', style: AppTypography.formLabel),
            const SizedBox(height: 8),
            DropdownButtonFormField<Employee>(
              value: _selectedEmployee,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select employee',
                prefixIcon: const Icon(AppIcons.user, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: widget.employees.map((emp) {
                return DropdownMenuItem(
                  value: emp,
                  child: Text(
                    '${emp.employeeCode} - ${emp.fullName}',
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedEmployee = val),
            ),
            const SizedBox(height: 20),

            // Date Selector
            Text('Date', style: AppTypography.formLabel),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.calendar,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                      style: AppTypography.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(
                      AppIcons.chevronDown,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Selector
            Text('Status', style: AppTypography.formLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((option) {
                final isSelected = _selectedStatus == option['value'];
                return InkWell(
                  onTap: () => setState(
                    () => _selectedStatus = option['value'] as String,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: AppSpacing.durationFast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (option['color'] as Color).withOpacity(0.12)
                          : AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? option['color'] as Color
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? option['color'] as Color
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          option['label'] as String,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected
                                ? option['color'] as Color
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Remarks
            Text('Remarks (optional)', style: AppTypography.formLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error / Success Messages
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.errorDark,
                  ),
                ),
              ),
            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.success,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.successDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Actions
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  text: _isLoading ? 'Saving...' : 'Mark Attendance',
                  icon: _isLoading ? null : AppIcons.check,
                  onPressed: _isLoading ? null : _handleSubmit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _handleSubmit() async {
    if (_selectedEmployee == null) {
      setState(() => _error = 'Please select an employee');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final now = DateTime.now();

      final record = AttendanceRecord(
        id: '',
        employeeId: _selectedEmployee!.id,
        employeeCode: _selectedEmployee!.employeeCode,
        date: _selectedDate,
        status: _selectedStatus,
        hoursWorked: _selectedStatus == 'present'
            ? 8.0
            : (_selectedStatus == 'half_day' ? 4.0 : 0),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        createdAt: now,
        updatedAt: now,
        createdBy: user?.userId ?? 'hr',
      );

      await ref.read(attendanceProvider.notifier).markAttendance(record);

      setState(() {
        _isLoading = false;
        _successMessage =
            'Attendance marked as ${_selectedStatus.replaceAll('_', ' ')} for ${_selectedEmployee!.fullName}';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}
