import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/salary_models.dart';
import '../../domain/providers/salary_providers.dart';

/// Screen to view advance salary details
class AdvanceSalaryDetailsScreen extends ConsumerStatefulWidget {
  final AdvanceSalary advance;

  const AdvanceSalaryDetailsScreen({
    Key? key,
    required this.advance,
  }) : super(key: key);

  @override
  ConsumerState<AdvanceSalaryDetailsScreen> createState() =>
      _AdvanceSalaryDetailsScreenState();
}

class _AdvanceSalaryDetailsScreenState
    extends ConsumerState<AdvanceSalaryDetailsScreen> {
  late TextEditingController _approveRemarksController;

  @override
  void initState() {
    super.initState();
    _approveRemarksController = TextEditingController();
  }

  @override
  void dispose() {
    _approveRemarksController.dispose();
    super.dispose();
  }

  Future<void> _approveAdvance() async {
    try {
      await ref
          .read(advanceSalaryProvider.notifier)
          .approveAdvance(
            widget.advance.id,
            'HR User',
            remarks: _approveRemarksController.text.isNotEmpty
                ? _approveRemarksController.text
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advance approved successfully')),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'approved':
        return Colors.blue;
      case 'partial':
        return Colors.orange;
      case 'cleared':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(advanceSalaryProvider).isSaving;
    final advance = widget.advance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: _getStatusColor(advance.status).withOpacity(0.1),
                border: Border.all(
                  color: _getStatusColor(advance.status),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getStatusLabel(advance.status),
                    style: AppTypography.titleLarge.copyWith(
                      color: _getStatusColor(advance.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Request Date: ${_formatDate(advance.requestDate)}',
                    style: AppTypography.bodySmall,
                  ),
                  if (advance.approvalDate != null)
                    Text(
                      'Approved Date: ${_formatDate(advance.approvalDate!)}',
                      style: AppTypography.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Amount Information
            _buildSection(
              'Amount Information',
              [
                _buildInfoRow('Advance Amount', '₹${advance.advanceAmount.toStringAsFixed(2)}'),
                _buildInfoRow('Repaid Amount', '₹${advance.repaidAmount.toStringAsFixed(2)}'),
                _buildInfoRow('Pending Amount', '₹${advance.pendingAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Installment Information
            _buildSection(
              'Repayment Information',
              [
                _buildInfoRow('Total Installments', advance.installments.toString()),
                _buildInfoRow(
                  'Cleared Installments',
                  advance.installmentsCleared.toString(),
                ),
                _buildInfoRow(
                  'Repayment Progress',
                  '${advance.repaymentPercentage.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: advance.repaymentPercentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  advance.isCleared ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Reason
            _buildSection(
              'Reason',
              [
                Text(
                  advance.reason,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Additional Info
            if (advance.remarks != null)
              _buildSection(
                'Remarks',
                [
                  Text(
                    advance.remarks!,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),

            // Approval Button (if pending)
            if (advance.status == 'pending')
              Column(
                children: [
                  TextField(
                    controller: _approveRemarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add remarks (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _approveAdvance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
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
                              'Approve Advance',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),

            // Cleared Status Info
            if (advance.isCleared)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Advance Cleared',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (advance.clearanceDate != null)
                            Text(
                              'Cleared on: ${_formatDate(advance.clearanceDate!)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
