import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/salary_models.dart';
import '../../domain/providers/salary_providers.dart';
import 'package:uuid/uuid.dart';

/// Screen for requesting advance salary
class AdvanceSalaryRequestScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeCode;

  const AdvanceSalaryRequestScreen({
    Key? key,
    required this.employeeId,
    required this.employeeCode,
  }) : super(key: key);

  @override
  ConsumerState<AdvanceSalaryRequestScreen> createState() =>
      _AdvanceSalaryRequestScreenState();
}

class _AdvanceSalaryRequestScreenState
    extends ConsumerState<AdvanceSalaryRequestScreen> {
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late TextEditingController _installmentsController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _reasonController = TextEditingController();
    _installmentsController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final amount = double.tryParse(_amountController.text);
    final reason = _reasonController.text.trim();
    final installments = int.tryParse(_installmentsController.text) ?? 1;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    final advance = AdvanceSalary(
      id: const Uuid().v4(),
      employeeId: widget.employeeId,
      employeeCode: widget.employeeCode,
      advanceAmount: amount,
      reason: reason,
      status: 'pending',
      repaidAmount: 0,
      pendingAmount: amount,
      installments: installments,
      installmentsCleared: 0,
      requestDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref
          .read(advanceSalaryProvider.notifier)
          .createAdvanceRequest(advance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advance request submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(advanceSalaryProvider).isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Advance Salary'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Field
            Text(
              'Advance Amount',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Reason Field
            Text(
              'Reason for Advance',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason for requesting advance',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Installments Field
            Text(
              'Number of Installments',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _installmentsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Number of months to repay',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
