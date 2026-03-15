import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../data/models/experience_model.dart';
import '../../domain/providers/experience_providers.dart';

class ExperienceDialog extends ConsumerStatefulWidget {
  final String employeeId;
  final WorkExperience? initialExperience;

  const ExperienceDialog({
    required this.employeeId,
    this.initialExperience,
    super.key,
  });

  @override
  ConsumerState<ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends ConsumerState<ExperienceDialog> {
  late TextEditingController _companyController;
  late TextEditingController _designationController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final exp = widget.initialExperience;
    _companyController = TextEditingController(text: exp?.companyName);
    _designationController = TextEditingController(text: exp?.designation);
    _locationController = TextEditingController(text: exp?.location);
    _descriptionController = TextEditingController(text: exp?.description);
    _startDate = exp?.startDate ?? DateTime.now().subtract(const Duration(days: 365));
    _endDate = exp?.endDate;
    _isCurrent = exp?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _designationController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_companyController.text.trim().isEmpty || _designationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Company and Designation')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final experience = WorkExperience(
        id: widget.initialExperience?.id ?? '', // ID assigned by repository/Appwrite
        employeeId: widget.employeeId,
        companyName: _companyController.text.trim(),
        designation: _designationController.text.trim(),
        startDate: _startDate,
        endDate: _isCurrent ? null : _endDate,
        isCurrent: _isCurrent,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        createdAt: widget.initialExperience?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.initialExperience != null) {
        await ref.read(experienceProvider.notifier).updateExperience(experience);
      } else {
        await ref.read(experienceProvider.notifier).addExperience(experience);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialExperience != null ? 'Experience updated' : 'Experience added'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialExperience != null ? 'Edit Experience' : 'Add Experience',
                    style: AppTypography.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Company & Designation
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Company Name *',
                      controller: _companyController,
                      hint: 'e.g. Google',
                      icon: AppIcons.department,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField(
                      label: 'Designation *',
                      controller: _designationController,
                      hint: 'e.g. Senior Developer',
                      icon: AppIcons.designation,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Start Date *',
                      date: _startDate,
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('End Date', style: AppTypography.formLabel),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isCurrent,
                                  onChanged: (v) => setState(() => _isCurrent = v ?? false),
                                  visualDensity: VisualDensity.compact,
                                  activeColor: AppColors.primary,
                                ),
                                Text('Current', style: AppTypography.caption),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!_isCurrent)
                          _buildDatePicker(
                            label: '', // Hide redundant label
                            date: _endDate,
                            onTap: () => _selectDate(false),
                            hint: 'Select End Date',
                          )
                        else
                          Container(
                            height: 48,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Present', style: AppTypography.bodyMedium),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location
              _buildField(
                label: 'Location',
                controller: _locationController,
                hint: 'e.g. Noida, India',
                icon: AppIcons.location,
              ),
              const SizedBox(height: 20),

              // Description
              _buildField(
                label: 'Description',
                controller: _descriptionController,
                hint: 'Key responsibilities and achievements...',
                icon: AppIcons.documents,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.initialExperience != null ? 'Update' : 'Add Experience'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.formLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    String hint = 'Select Date',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTypography.formLabel),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: onTap,
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
                Icon(AppIcons.calendar, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 10),
                Text(
                  date != null ? DateFormat('MMM dd, yyyy').format(date) : hint,
                  style: AppTypography.bodyMedium.copyWith(
                    color: date != null ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
