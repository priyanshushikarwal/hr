import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/salary_models.dart';
import '../../domain/providers/salary_providers.dart';
import 'advance_salary_request_screen.dart';
import 'advance_salary_details_screen.dart';

/// Screen to view all advance salary requests and status
class AdvanceSalaryListScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeCode;
  final String? employeeName;
  final bool isHRView; // If true, show all employees' advances

  const AdvanceSalaryListScreen({
    Key? key,
    required this.employeeId,
    required this.employeeCode,
    this.employeeName,
    this.isHRView = false,
  }) : super(key: key);

  @override
  ConsumerState<AdvanceSalaryListScreen> createState() =>
      _AdvanceSalaryListScreenState();
}

class _AdvanceSalaryListScreenState
    extends ConsumerState<AdvanceSalaryListScreen> {
  @override
  void initState() {
    super.initState();
    // Load advances for the employee
    Future.microtask(() {
      ref
          .read(advanceSalaryProvider.notifier)
          .loadEmployeeAdvances(widget.employeeId);
    });
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
    final state = ref.watch(advanceSalaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isHRView
              ? 'Advance Salary Requests'
              : 'My Advance Salary',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Pending: ₹${state.totalPendingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${state.pendingCount} advances',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.advances.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.request_quote_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No advance requests yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (!widget.isHRView)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdvanceSalaryRequestScreen(
                                  employeeId: widget.employeeId,
                                  employeeCode: widget.employeeCode,
                                ),
                              ),
                            ).then((_) {
                              ref
                                  .read(advanceSalaryProvider.notifier)
                                  .loadEmployeeAdvances(
                                    widget.employeeId,
                                  );
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Request Advance'),
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Card
                    Container(
                      margin: const EdgeInsets.all(AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Total Approved',
                                style: AppTypography.labelSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '₹${state.totalApprovedAmount.toStringAsFixed(0)}',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Still Pending',
                                style: AppTypography.labelSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '₹${state.totalPendingAmount.toStringAsFixed(0)}',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Repayment %',
                                style: AppTypography.labelSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                state.totalApprovedAmount > 0
                                    ? '${(((state.totalApprovedAmount - state.totalPendingAmount) / state.totalApprovedAmount) * 100).toStringAsFixed(0)}%'
                                    : '0%',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // List of advances
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: state.advances.length,
                        itemBuilder: (context, index) {
                          final advance = state.advances[index];
                          return _AdvanceCard(
                            advance: advance,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdvanceSalaryDetailsScreen(
                                    advance: advance,
                                  ),
                                ),
                              ).then((_) {
                                ref
                                    .read(advanceSalaryProvider.notifier)
                                    .loadEmployeeAdvances(
                                      widget.employeeId,
                                    );
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: !widget.isHRView && state.advances.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdvanceSalaryRequestScreen(
                      employeeId: widget.employeeId,
                      employeeCode: widget.employeeCode,
                    ),
                  ),
                ).then((_) {
                  ref
                      .read(advanceSalaryProvider.notifier)
                      .loadEmployeeAdvances(
                        widget.employeeId,
                      );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('New Request'),
            )
          : null,
    );
  }
}

class _AdvanceCard extends StatelessWidget {
  final AdvanceSalary advance;
  final VoidCallback onTap;

  const _AdvanceCard({
    Key? key,
    required this.advance,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(advance.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${advance.advanceAmount.toStringAsFixed(0)}',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        advance.reason,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(advance.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: advance.advanceAmount > 0
                      ? (advance.repaidAmount / advance.advanceAmount)
                          .clamp(0.0, 1.0)
                      : 0,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    advance.isCleared ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repaid: ₹${advance.repaidAmount.toStringAsFixed(0)}',
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    'Pending: ₹${advance.pendingAmount.toStringAsFixed(0)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Installments: ${advance.installmentsCleared}/${advance.installments}',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
