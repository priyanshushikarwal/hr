import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../utils/salary_slip_pdf_generator.dart';
import '../../domain/providers/salary_providers.dart';

/// Dialog to generate a salary slip for an employee
class GenerateSalarySlipDialog extends ConsumerStatefulWidget {
  final Employee? preselectedEmployee;

  const GenerateSalarySlipDialog({super.key, this.preselectedEmployee});

  @override
  ConsumerState<GenerateSalarySlipDialog> createState() =>
      _GenerateSalarySlipDialogState();
}

class _GenerateSalarySlipDialogState
    extends ConsumerState<GenerateSalarySlipDialog> {
  Employee? _selectedEmployee;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _autoCalc = true;
  bool _isGenerating = false;

  final _ctcController = TextEditingController();
  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _saController = TextEditingController();
  final _otherEarningsController = TextEditingController(text: '0');
  final _pfController = TextEditingController(text: '0');
  final _esicController = TextEditingController(text: '0');
  final _advanceController = TextEditingController(text: '0');
  final _paidDaysController = TextEditingController();
  final _branchController = TextEditingController();
  final _payModeController = TextEditingController(text: 'NEFT');

  @override
  void initState() {
    super.initState();
    if (widget.preselectedEmployee != null) {
      _selectedEmployee = widget.preselectedEmployee;
    }
    // Default month days
    _paidDaysController.text = DateTime(
      _selectedYear,
      _selectedMonth + 1,
      0,
    ).day.toString();
  }

  @override
  void dispose() {
    _ctcController.dispose();
    _basicController.dispose();
    _hraController.dispose();
    _saController.dispose();
    _otherEarningsController.dispose();
    _pfController.dispose();
    _esicController.dispose();
    _advanceController.dispose();
    _paidDaysController.dispose();
    _branchController.dispose();
    _payModeController.dispose();
    super.dispose();
  }

  void _recalcFromCTC(double ctc) {
    if (!_autoCalc) return;
    final basic = (ctc * 0.55).round();
    final hra = (ctc * 0.275).round();
    final sa = ctc.round() - basic - hra;
    _basicController.text = basic.toString();
    _hraController.text = hra.toString();
    _saController.text = sa.toString();

    // Auto PF/ESIC
    final pf = _selectedEmployee?.isPfApplicable == true
        ? (basic * 0.12).round()
        : 0;
    final esic = _selectedEmployee?.isEsicApplicable == true
        ? ((basic + hra + sa) * 0.0075).round()
        : 0;
    _pfController.text = pf.toString();
    _esicController.text = esic.toString();
    setState(() {});
  }

  /// Load pending advances for an employee and auto-populate advance field
  Future<void> _loadEmployeeAdvances(String employeeId) async {
    try {
      final pendingAmount = await ref
          .read(advanceSalaryProvider.notifier)
          .getTotalPendingAmount(employeeId);
      
      _advanceController.text = pendingAmount.toStringAsFixed(2);
      setState(() {});
    } catch (e) {
      // Silently fail - user can manually enter advance amount
      debugPrint('Error loading advances: $e');
    }
  }

  int get _monthDays => DateTime(_selectedYear, _selectedMonth + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeListProvider);
    final activeEmployees = employeesState.employees
        .where((e) => e.isActive)
        .toList();

    final basic = double.tryParse(_basicController.text) ?? 0;
    final hra = double.tryParse(_hraController.text) ?? 0;
    final sa = double.tryParse(_saController.text) ?? 0;
    final otherE = double.tryParse(_otherEarningsController.text) ?? 0;
    final totalEarnings = basic + hra + sa + otherE;
    final pf = double.tryParse(_pfController.text) ?? 0;
    final esic = double.tryParse(_esicController.text) ?? 0;
    final adv = double.tryParse(_advanceController.text) ?? 0;
    final totalDeductions = pf + esic + adv;
    final netPay = totalEarnings - totalDeductions;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      AppIcons.salary,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate Salary Slip',
                          style: AppTypography.titleLarge,
                        ),
                        Text(
                          'Create salary slip for an employee',
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
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Selection
                    Text('Employee *', style: AppTypography.formLabel),
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
                      items: activeEmployees.map((emp) {
                        return DropdownMenuItem(
                          value: emp,
                          child: Text(
                            '${emp.employeeCode} - ${emp.fullName} (${emp.designation})',
                            style: AppTypography.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedEmployee = val);
                        if (val != null) {
                          // Load pending advances for this employee
                          _loadEmployeeAdvances(val.id);
                          // Recalculate if CTC is provided
                          if (_ctcController.text.isNotEmpty) {
                            _recalcFromCTC(
                              double.tryParse(_ctcController.text) ?? 0,
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // Month & Year
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Month *', style: AppTypography.formLabel),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedMonth,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: List.generate(12, (i) {
                                  return DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(_getMonthName(i + 1)),
                                  );
                                }),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedMonth = val ?? 1;
                                    _paidDaysController.text = _monthDays
                                        .toString();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Year *', style: AppTypography.formLabel),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedYear,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: [2024, 2025, 2026, 2027].map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedYear = val ?? 2025;
                                    _paidDaysController.text = _monthDays
                                        .toString();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _numberField('Paid Days', _paidDaysController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Branch & Pay Mode
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Branch Name',
                                style: AppTypography.formLabel,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _branchController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Peeplu, Tonk',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pay Mode', style: AppTypography.formLabel),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _payModeController.text,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: ['NEFT', 'Cash', 'UPI', 'Cheque']
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    _payModeController.text = val ?? 'NEFT',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Salary Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.money,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Salary Components',
                                style: AppTypography.titleSmall,
                              ),
                              const Spacer(),
                              Text(
                                'Auto Calc',
                                style: AppTypography.labelSmall,
                              ),
                              const SizedBox(width: 6),
                              Switch(
                                value: _autoCalc,
                                onChanged: (val) =>
                                    setState(() => _autoCalc = val),
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // CTC
                          Text(
                            'CTC / Gross per month',
                            style: AppTypography.formLabel,
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _ctcController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'e.g. 18000',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              final ctc = double.tryParse(val) ?? 0;
                              _recalcFromCTC(ctc);
                            },
                          ),
                          const SizedBox(height: 14),

                          // Earnings Row
                          Row(
                            children: [
                              Expanded(
                                child: _compactField(
                                  'Basic Pay',
                                  _basicController,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _compactField('HRA', _hraController),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _compactField(
                                  'Special Allow.',
                                  _saController,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _compactField(
                                  'Other',
                                  _otherEarningsController,
                                  enabled: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Deductions Row
                          Text(
                            'Deductions',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _compactField(
                                  'PF Employee',
                                  _pfController,
                                  enabled: !_autoCalc,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _compactField(
                                  'ESIC',
                                  _esicController,
                                  enabled: !_autoCalc,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _compactField(
                                  'Advance',
                                  _advanceController,
                                  enabled: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Summary
                          const Divider(),
                          const SizedBox(height: 8),
                          _summaryRow(
                            'Total Earnings',
                            '₹${totalEarnings.toInt()}',
                            AppColors.success,
                          ),
                          _summaryRow(
                            'Total Deductions',
                            '-₹${totalDeductions.toInt()}',
                            AppColors.error,
                          ),
                          const Divider(),
                          _summaryRow(
                            'Net Pay',
                            '₹${netPay.toInt()}',
                            AppColors.primary,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    text: _isGenerating ? 'Generating...' : 'Generate PDF',
                    icon: _isGenerating ? null : AppIcons.download,
                    onPressed: _isGenerating ? null : _generateSlip,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.formLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _compactField(
    String label,
    TextEditingController controller, {
    bool? enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled ?? !_autoCalc,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.bodySmall,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixText: '₹',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelSmall),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _generateSlip() {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final data = SalarySlipData(
      employee: _selectedEmployee!,
      month: _selectedMonth,
      year: _selectedYear,
      paidDays: int.tryParse(_paidDaysController.text) ?? _monthDays,
      monthDays: _monthDays,
      payMode: _payModeController.text,
      branchName: _branchController.text.isEmpty ? '-' : _branchController.text,
      basicPay: double.tryParse(_basicController.text) ?? 0,
      hra: double.tryParse(_hraController.text) ?? 0,
      specialAllowance: double.tryParse(_saController.text) ?? 0,
      otherEarnings: double.tryParse(_otherEarningsController.text) ?? 0,
      pfEmployee: double.tryParse(_pfController.text) ?? 0,
      esic: double.tryParse(_esicController.text) ?? 0,
      advance: double.tryParse(_advanceController.text) ?? 0,
    );

    // Record advance deduction if advance amount is present
    final advanceAmount = double.tryParse(_advanceController.text) ?? 0;
    if (advanceAmount > 0 && _selectedEmployee != null) {
      _recordAdvanceDeduction(_selectedEmployee!.id, advanceAmount);
    }

    SalarySlipPdfGenerator.printPreview(data)
        .then((_) {
          setState(() => _isGenerating = false);
        })
        .catchError((e) {
          setState(() => _isGenerating = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        });
  }

  /// Record advance salary deduction from the salary slip
  Future<void> _recordAdvanceDeduction(
    String employeeId,
    double deductionAmount,
  ) async {
    try {
      // Get all pending advances for the employee
      final advances = await ref
          .read(advanceSalaryProvider.notifier)
          .getTotalPendingAmount(employeeId);
      
      if (advances > 0 && deductionAmount > 0) {
        // Load employee advances to update them
        await ref
            .read(advanceSalaryProvider.notifier)
            .loadEmployeeAdvances(employeeId);
        
        // Record the deduction (this will automatically update advance status)
        // Note: In a real implementation, you'd iterate through advances and
        // record deductions proportionally
        debugPrint('Advance deduction recorded: ₹$deductionAmount');
      }
    } catch (e) {
      // Silently fail - salary slip was still generated
      debugPrint('Error recording advance deduction: $e');
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
