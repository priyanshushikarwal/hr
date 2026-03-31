import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../attendance/domain/providers/attendance_providers.dart';
import '../../domain/providers/salary_providers.dart';
import '../../data/models/salary_models.dart';
import '../../../payments/domain/providers/payment_providers.dart';
import '../../../payments/data/models/payment_model.dart';
import 'package:uuid/uuid.dart';

class GeneratePayrollScreen extends ConsumerStatefulWidget {
  const GeneratePayrollScreen({super.key});

  @override
  ConsumerState<GeneratePayrollScreen> createState() => _GeneratePayrollScreenState();
}

class _GeneratePayrollScreenState extends ConsumerState<GeneratePayrollScreen> {
  DateTime _selectedMonth = DateTime.now();
  Employee? _selectedEmployee;
  OfficeSalaryStructure? _salaryStructure;
  double _adjustment = 0;
  double _penalty = 0;
  
  // Dynamic edits for ESIC/PF
  double _overriddenPf = 0;
  double _overriddenEsic = 0;
  bool _isPfOverridden = false;
  bool _isEsicOverridden = false;

  final TextEditingController _adjustmentController = TextEditingController();
  final TextEditingController _penaltyController = TextEditingController();
  final TextEditingController _pfController = TextEditingController();
  final TextEditingController _esicController = TextEditingController();

  @override
  void dispose() {
    _adjustmentController.dispose();
    _penaltyController.dispose();
    _pfController.dispose();
    _esicController.dispose();
    super.dispose();
  }

  void _onEmployeeSelected(Employee? employee) async {
    setState(() {
      _selectedEmployee = employee;
      _salaryStructure = null;
      _isPfOverridden = false;
      _isEsicOverridden = false;
    });

    if (employee != null) {
      // Load salary structure
      await ref.read(officeSalaryProvider.notifier).loadSalary(employee.id);
      final structure = ref.read(officeSalaryProvider).salary;
      
      if (mounted) {
        setState(() {
          _salaryStructure = structure;
          if (structure != null) {
            _overriddenPf = structure.pfEmployee;
            _overriddenEsic = structure.esicEmployee;
            _pfController.text = _overriddenPf.toStringAsFixed(2);
            _esicController.text = _overriddenEsic.toStringAsFixed(2);
          }
        });
      }

      // Pre-load attendance
      await ref.read(attendanceProvider.notifier).loadAttendance(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
        employeeId: employee.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeListProvider);
    final employees = employeeState.employees;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildSelectionCard(employees),
                      const SizedBox(height: AppSpacing.md),
                      if (_selectedEmployee != null) ...[
                        _buildAttendanceSummary(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: _selectedEmployee == null
                      ? _buildEmptyState()
                      : _buildSalaryCalculationPanel(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payroll Processing', style: AppTypography.headlineMedium),
        Text(
          'Run and process monthly payroll with automated compliance checks',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(List<Employee> employees) {
    return ContentCard(
      title: 'Configuration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Month', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: _showMonthPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: AppTypography.bodyMedium,
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<Employee>(
            label: 'Select Employee',
            value: _selectedEmployee,
            hint: 'Choose an employee...',
            prefixIcon: Icons.person_search,
            items: employees,
            itemLabel: (e) => '${e.employeeCode} - ${e.fullName}',
            onChanged: _onEmployeeSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    final attendanceState = ref.watch(attendanceProvider);
    
    if (attendanceState.isLoading) {
      return const ContentCard(child: Center(child: CircularProgressIndicator()));
    }

    final records = attendanceState.records;
    final summary = ref.read(attendanceRepositoryProvider).getMonthSummary(
      records, 
      _selectedEmployee!.id, 
      _selectedEmployee!.employeeCode, 
      _selectedMonth.month, 
      _selectedMonth.year
    );

    return ContentCard(
      title: 'Attendance Summary',
      child: Column(
        children: [
          _buildSummaryRow('Total Work Days', '${summary.totalDays}'),
          _buildSummaryRow('Present Days', '${summary.presentDays}', color: AppColors.success),
          _buildSummaryRow('Late Days', '${summary.lateDays}', color: AppColors.warning),
          _buildSummaryRow('Absent Days', '${summary.absentDays}', color: AppColors.error),
          _buildSummaryRow('Half Days', '${summary.halfDays}', color: AppColors.warning),
          _buildSummaryRow('Leave Days', '${summary.leaveDays}', color: AppColors.info),
          _buildSummaryRow('Hol/Weekends', '${summary.holidays + summary.weekends}'),
          const Divider(),
          _buildSummaryRow('Payable Days', '${summary.presentDays + summary.lateDays + summary.holidays + summary.weekends + (summary.halfDays * 0.5)}', 
            isBold: true, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Select an employee to start processing payroll', style: AppTypography.bodyLarge),
            Text('Automated calculations will appear here after selection', style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryCalculationPanel() {
    if (_salaryStructure == null) {
      return const ContentCard(child: Center(child: CircularProgressIndicator()));
    }

    final attendanceState = ref.watch(attendanceProvider);

    final records = attendanceState.records;
    final summary = ref.read(attendanceRepositoryProvider).getMonthSummary(
      records, 
      _selectedEmployee!.id, 
      _selectedEmployee!.employeeCode, 
      _selectedMonth.month, 
      _selectedMonth.year
    );

    final daysInMonth = summary.totalDays;
    final payableDays =
        summary.presentDays +
        summary.lateDays +
        summary.holidays +
        summary.weekends +
        (summary.halfDays * 0.5);
    final attendanceFactor = payableDays / daysInMonth;
    final dailyWage = daysInMonth == 0 ? 0.0 : (_salaryStructure!.grossSalary / daysInMonth);
    final lateDaysBeyondGrace = summary.lateDays <= 3 ? 0 : summary.lateDays - 3;
    final lateDeduction = lateDaysBeyondGrace * dailyWage * 0.25;

    final proRataBasic = _salaryStructure!.basicSalary * attendanceFactor;
    final proRataGross = _salaryStructure!.grossSalary * attendanceFactor;
    
    final pendingAdvancesAsync = ref.watch(employeeAdvancesProvider(_selectedEmployee!.id));
    final pendingAdvances = pendingAdvancesAsync.maybeWhen(
      data: (list) => list.where((a) => a.status == 'approved' || a.status == 'partial').toList(),
      orElse: () => <AdvanceSalary>[],
    );

    final totalPendingAmount = pendingAdvances.fold<double>(0, (sum, a) => sum + a.pendingAmount);

    final advanceDeduction = totalPendingAmount > 0 
        ? (totalPendingAmount > proRataGross * 0.5 ? proRataGross * 0.3 : totalPendingAmount) 
        : 0.0;

    final pf = _isPfOverridden ? _overriddenPf : (proRataBasic * 0.12);
    final esic = _isEsicOverridden ? _overriddenEsic : (proRataGross * 0.0075);
    
    final netSalary =
        proRataGross -
        pf -
        esic -
        lateDeduction -
        _penalty +
        _adjustment -
        advanceDeduction;

    return Column(
      children: [
        ContentCard(
          title: 'Earnings Breakdown (Pro-rata)',
          child: Column(
            children: [
              _buildCalcRow('Monthly Base Salary', _salaryStructure!.grossSalary),
              _buildCalcRow('Attendance Factor', attendanceFactor, isAmount: false),
              const Divider(),
              _buildCalcRow('Pro-rata Gross', proRataGross, isBold: true),
              _buildCalcRow('Basic (for PF)', proRataBasic, isSmall: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        ContentCard(
          title: 'Deductions & Statutory Compliance',
          child: Column(
            children: [
              _buildStatutoryInput('Provident Fund (PF)', _pfController, (val) {
                setState(() {
                  _isPfOverridden = true;
                  _overriddenPf = double.tryParse(val) ?? 0;
                });
              }),
              _buildStatutoryInput('ESIC Contribution', _esicController, (val) {
                setState(() {
                  _isEsicOverridden = true;
                  _overriddenEsic = double.tryParse(val) ?? 0;
                });
              }),
              const Divider(),
              _buildSummaryRow(
                'Late Deduction',
                '-${_formatCurrency(lateDeduction)}',
                color: lateDeduction > 0 ? AppColors.error : AppColors.success,
              ),
              _buildSummaryRow(
                'Late Days Beyond Grace',
                '$lateDaysBeyondGrace',
                color: AppColors.warning,
              ),
              _buildSummaryRow('Advance Recovery', '-${_formatCurrency(advanceDeduction)}', color: AppColors.error),
              
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Adjustment (+)',
                      controller: _adjustmentController,
                      prefixIcon: Icons.add_circle_outline,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _adjustment = double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Penalty (-)',
                      controller: _penaltyController,
                      prefixIcon: Icons.remove_circle_outline,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _penalty = double.tryParse(v) ?? 0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        _buildNetSalaryFooter(netSalary, advanceDeduction, pendingAdvances),
      ],
    );
  }

  Widget _buildCalcRow(String label, double value, {bool isBold = false, bool isSmall = false, bool isAmount = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isSmall ? AppTypography.caption : AppTypography.bodyMedium),
          Text(
            isAmount ? _formatCurrency(value) : value.toStringAsFixed(2),
            style: (isSmall ? AppTypography.bodySmall : AppTypography.bodyLarge).copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutoryInput(String label, TextEditingController controller, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: AppTypography.bodyMedium)),
          const Spacer(),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                prefixText: '₹ ',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetSalaryFooter(double netAmount, double advanceDeduction, List<AdvanceSalary> pendingAdvances) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NET PAYABLE', style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
              Text(
                _formatCurrency(netAmount),
                style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Process Payroll',
            icon: Icons.check_circle_outline,
            onPressed: () => _confirmProcess(netAmount, advanceDeduction, pendingAdvances),
          ),
        ],
      ),
    );
  }

  void _confirmProcess(double netAmount, double advanceDeduction, List<AdvanceSalary> advances) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payroll Processing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to process payroll for ${_selectedEmployee!.fullName}?'),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow('Month', DateFormat('MMMM yyyy').format(_selectedMonth)),
            if (advanceDeduction > 0)
              _buildSummaryRow('Advance Recovery', '-${_formatCurrency(advanceDeduction)}', color: AppColors.error),
            _buildSummaryRow('Net Payable', _formatCurrency(netAmount), isBold: true, color: AppColors.success),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayroll(netAmount, advanceDeduction, advances);
            },
            child: const Text('Confirm & Process'),
          ),
        ],
      ),
    );
  }

  void _processPayroll(double netAmount, double advanceDeduction, List<AdvanceSalary> advances) async {
    try {
      final recordId = const Uuid().v4();
      final record = PaymentRecord(
        id: recordId,
        employeeId: _selectedEmployee!.id,
        employeeCode: _selectedEmployee!.employeeCode,
        employeeName: _selectedEmployee!.fullName,
        month: _selectedMonth.month,
        year: _selectedMonth.year,
        grossSalary: _salaryStructure!.grossSalary,
        totalDeductions: _salaryStructure!.grossSalary - netAmount,
        netSalary: netAmount,
        paymentMode: 'bank_transfer',
        status: 'processed',
        isLocked: true,
        remarks: 'Processed via Payroll Run',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(paymentListProvider.notifier).processSalary(record);

      // Process advance deductions if any
      if (advanceDeduction > 0) {
        double remainingDeduction = advanceDeduction;
        for (final adv in advances) {
          if (remainingDeduction <= 0) break;
          
          final amountToDeduct = remainingDeduction > adv.pendingAmount 
              ? adv.pendingAmount 
              : remainingDeduction;
          
          await ref.read(advanceSalaryProvider.notifier).recordAdvanceDeduction(
            adv.id, 
            amountToDeduct
          );
          
          remainingDeduction -= amountToDeduct;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll processed successfully!'), backgroundColor: AppColors.success),
        );
        _onEmployeeSelected(null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
      if (_selectedEmployee != null) {
        _onEmployeeSelected(_selectedEmployee);
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }
}
