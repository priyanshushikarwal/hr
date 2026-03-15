import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../domain/providers/salary_providers.dart';
import '../../data/models/salary_models.dart';
import 'package:uuid/uuid.dart';

class AllAdvanceTrackingScreen extends ConsumerStatefulWidget {
  const AllAdvanceTrackingScreen({super.key});

  @override
  ConsumerState<AllAdvanceTrackingScreen> createState() => _AllAdvanceTrackingScreenState();
}

class _AllAdvanceTrackingScreenState extends ConsumerState<AllAdvanceTrackingScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'pending', 'partial', 'cleared'

  @override
  Widget build(BuildContext context) {
    final advancesAsync = ref.watch(allPendingAdvancesProvider);
    final employeeState = ref.watch(employeeListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildFilters(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: advancesAsync.when(
                data: (advances) {
                  final filtered = advances.where((adv) {
                    final matchesSearch = adv.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        adv.reason.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesStatus = _statusFilter == 'all' || adv.status == _statusFilter;
                    return matchesSearch && matchesStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildAdvanceTable(filtered);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAdvanceDialog(context, employeeState.employees),
        label: const Text('Add Advance'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Advance Payment Tracking', style: AppTypography.headlineMedium),
        Text(
          'Manage and track advance payments given to employees. Pending amounts are automatically deducted during payroll.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextField(
            label: 'Search',
            hint: 'Search by employee code or reason...',
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppDropdownField<String>(
            label: 'Status',
            value: _statusFilter,
            items: const ['all', 'pending', 'approved', 'partial', 'cleared'],
            itemLabel: (s) => s[0].toUpperCase() + s.substring(1),
            onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No advance records found', style: AppTypography.titleMedium),
          Text('Try adjusting your filters or add a new advance', style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAdvanceTable(List<AdvanceSalary> advances) {
    return ContentCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.backgroundSecondary),
          columns: const [
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Employee ID')),
            DataColumn(label: Text('Reason')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Repaid')),
            DataColumn(label: Text('Pending')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Action')),
          ],
          rows: advances.map((adv) {
            final statusColor = _getStatusColor(adv.status);
            return DataRow(cells: [
              DataCell(Text(adv.employeeCode, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(adv.employeeId)),
              DataCell(Text(adv.reason)),
              DataCell(Text('₹${adv.advanceAmount.toStringAsFixed(0)}')),
              DataCell(Text('₹${adv.repaidAmount.toStringAsFixed(0)}')),
              DataCell(Text('₹${adv.pendingAmount.toStringAsFixed(0)}', 
                style: TextStyle(color: adv.pendingAmount > 0 ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor),
                ),
                child: Text(adv.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )),
              DataCell(Text(DateFormat('dd MMM yyyy').format(adv.requestDate))),
              DataCell(Row(
                children: [
                  if (adv.status != 'cleared')
                    AppIconButton(
                      icon: Icons.check_circle_outline,
                      tooltip: 'Mark as Paid',
                      color: AppColors.success,
                      onPressed: () => _confirmMarkAsPaid(adv),
                    ),
                  AppIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Remove Record',
                    color: AppColors.error,
                    onPressed: () => _confirmDelete(adv),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'approved': return AppColors.info;
      case 'partial': return Colors.orange;
      case 'cleared': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.textTertiary;
    }
  }

  void _showAddAdvanceDialog(BuildContext context, List<Employee> employees) {
    Employee? selectedEmployee;
    double amount = 0;
    String reason = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Advance Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdownField<Employee>(
                  label: 'Employee',
                  value: selectedEmployee,
                  items: employees,
                  itemLabel: (e) => '${e.employeeCode} - ${e.fullName}',
                  onChanged: (e) => setDialogState(() => selectedEmployee = e),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Amount (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => amount = double.tryParse(v) ?? 0,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Reason',
                  hint: 'e.g. Personal emergency, Wedding, etc.',
                  onChanged: (v) => reason = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            PrimaryButton(
              text: 'Add Advance',
              onPressed: () {
                if (selectedEmployee == null || amount <= 0 || reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                _addAdvance(selectedEmployee!, amount, reason);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addAdvance(Employee employee, double amount, String reason) async {
    final advance = AdvanceSalary(
      id: const Uuid().v4(),
      employeeId: employee.id,
      employeeCode: employee.employeeCode,
      advanceAmount: amount,
      pendingAmount: amount,
      reason: reason,
      status: 'approved', // HR directly adding it is approved
      requestDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(advanceSalaryProvider.notifier).createAdvanceRequest(advance);
      ref.invalidate(allPendingAdvancesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advance added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmMarkAsPaid(AdvanceSalary adv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Fully Paid'),
        content: Text('Are you sure you want to mark the advance of ₹${adv.pendingAmount} for ${adv.employeeCode} as fully paid? This will clear the pending balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              _markAsPaid(adv);
              Navigator.pop(context);
            },
            child: const Text('Confirm & Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(AdvanceSalary adv) async {
    try {
      // Repay the full pending amount
      await ref.read(advanceSalaryProvider.notifier).recordAdvanceDeduction(adv.id, adv.pendingAmount);
      ref.invalidate(allPendingAdvancesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advance marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmDelete(AdvanceSalary adv) {
    // Logic for deletion if needed - usually advances aren't "deleted" but just marked.
    // However, if it's an error entry, HR should be able to remove it.
  }
}
