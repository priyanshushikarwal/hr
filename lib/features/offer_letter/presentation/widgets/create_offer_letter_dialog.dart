import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../data/models/offer_letter_model.dart';
import '../../domain/providers/offer_letter_providers.dart';
import '../../../auth/domain/providers/auth_providers.dart';

/// Create / Edit Offer Letter Dialog
class CreateOfferLetterDialog extends ConsumerStatefulWidget {
  final OfferLetter? existingLetter; // null for create, non-null for edit

  const CreateOfferLetterDialog({super.key, this.existingLetter});

  @override
  ConsumerState<CreateOfferLetterDialog> createState() =>
      _CreateOfferLetterDialogState();
}

class _CreateOfferLetterDialogState
    extends ConsumerState<CreateOfferLetterDialog> {
  Employee? _selectedEmployee;
  bool _useManualCandidate = false;
  DateTime _joiningDate = DateTime.now();
  final _ctcController = TextEditingController();
  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _saController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _reportingManagerController = TextEditingController();
  final _addressController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _autoCalc = true;
  String _manualEmployeeType = 'office';
  bool _isPfApplicable = true;
  bool _isEsicApplicable = true;

  bool get _isEditing => widget.existingLetter != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final l = widget.existingLetter!;
      _ctcController.text = l.ctc.toInt().toString();
      _remarksController.text = l.remarks ?? '';
      _joiningDate = l.joiningDate;
      _employeeNameController.text = l.employeeName;
      _employeeCodeController.text = l.employeeCode;
      _designationController.text = l.designation;
      _departmentController.text = l.department;
      _manualEmployeeType = l.employeeType.isEmpty ? 'office' : l.employeeType;
      _isPfApplicable = l.isPfApplicable;
      _isEsicApplicable = l.isEsicApplicable;
      _useManualCandidate = true;
      // Auto-calculate salary components from CTC
      _recalcSalary(l.ctc);
    }
  }

  void _recalcSalary(double ctc) {
    if (!_autoCalc) return;
    final gross = _calculateGrossFromCtc(ctc);
    final basic = (gross * 0.60).round();
    final hra = gross.round() - basic;
    final sa = 0;
    _basicController.text = basic.toString();
    _hraController.text = hra.toString();
    _saController.text = sa.toString();
  }

  @override
  void dispose() {
    _ctcController.dispose();
    _basicController.dispose();
    _hraController.dispose();
    _saController.dispose();
    _employeeNameController.dispose();
    _employeeCodeController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _reportingManagerController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeListProvider);
    final activeEmployees = employeesState.employees
        .where((e) => e.isActive)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 700),
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
                      AppIcons.offerLetter,
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
                          _isEditing
                              ? 'Edit Offer Letter'
                              : 'Create Offer Letter',
                          style: AppTypography.titleLarge,
                        ),
                        Text(
                          'Fill in the details for the offer letter',
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

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Selection (only for create)
                    if (!_isEditing) ...[
                      Text('Letter For', style: AppTypography.formLabel),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(AppIcons.user, size: 16),
                            label: Text('Existing Employee'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(AppIcons.edit, size: 16),
                            label: Text('Manual Candidate'),
                          ),
                        ],
                        selected: {_useManualCandidate},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _useManualCandidate = selection.first;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (_isEditing || _useManualCandidate) ...[
                      Text(
                        'Candidate Details *',
                        style: AppTypography.formLabel,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _employeeNameController,
                        decoration: InputDecoration(
                          hintText: 'Candidate full name',
                          prefixIcon: const Icon(AppIcons.user, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _designationController,
                              decoration: InputDecoration(
                                hintText: 'Designation',
                                prefixIcon: const Icon(
                                  AppIcons.designation,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _departmentController,
                              decoration: InputDecoration(
                                hintText: 'Department',
                                prefixIcon: const Icon(
                                  AppIcons.department,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _employeeCodeController,
                              decoration: InputDecoration(
                                hintText: 'Employee/Candidate Code (optional)',
                                prefixIcon: const Icon(
                                  AppIcons.employeeMaster,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _manualEmployeeType,
                              decoration: InputDecoration(
                                hintText: 'Employee type',
                                prefixIcon: const Icon(
                                  AppIcons.employees,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'office',
                                  child: Text('Office Employee'),
                                ),
                                DropdownMenuItem(
                                  value: 'factory',
                                  child: Text('Factory Employee'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _manualEmployeeType = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      Text('Select Employee *', style: AppTypography.formLabel),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Employee>(
                        value: _selectedEmployee,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Choose an employee',
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
                        onChanged: (val) => setState(() {
                          _selectedEmployee = val;
                          if (val != null) {
                            _isPfApplicable = val.isPfApplicable;
                            _isEsicApplicable = val.isEsicApplicable;
                          }
                        }),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Joining Date
                    Text('Joining Date *', style: AppTypography.formLabel),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _joiningDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _joiningDate = date);
                        }
                      },
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
                              DateFormat('dd MMMM yyyy').format(_joiningDate),
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
                    const SizedBox(height: 18),

                    // Reporting Manager
                    Text('Reporting Manager', style: AppTypography.formLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reportingManagerController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Shubham Sir (Manager)',
                        prefixIcon: const Icon(AppIcons.user, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Employee Address
                    Text('Employee Address', style: AppTypography.formLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Full address for the offer letter',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                                'Salary Breakup',
                                style: AppTypography.titleSmall,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    'Auto Calculate',
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
                            ],
                          ),
                          const SizedBox(height: 16),

                          // CTC
                          Text(
                            'CTC (Cost to Company) per month *',
                            style: AppTypography.formLabel,
                          ),
                          const SizedBox(height: 8),
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
                              _recalcSalary(ctc);
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'PF Applicable',
                                    style: AppTypography.labelSmall,
                                  ),
                                  value: _isPfApplicable,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _isPfApplicable = val;
                                      _recalcSalary(
                                        double.tryParse(_ctcController.text) ??
                                            0,
                                      );
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'ESIC Applicable',
                                    style: AppTypography.labelSmall,
                                  ),
                                  value: _isEsicApplicable,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _isEsicApplicable = val;
                                      _recalcSalary(
                                        double.tryParse(_ctcController.text) ??
                                            0,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Basic, HRA
                          Row(
                            children: [
                              Expanded(
                                child: _salaryField(
                                  'Basic (60% of Gross)',
                                  _basicController,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _salaryField(
                                  'HRA (40% of Gross)',
                                  _hraController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Computed values
                          if (_ctcController.text.isNotEmpty) ...[
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildEnhancedSalarySummary(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Remarks
                    Text('Remarks (optional)', style: AppTypography.formLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarksController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Any additional notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Error message
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
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
                  ],
                ),
              ),
            ),

            // Footer Actions
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
                    text: _isLoading
                        ? 'Saving...'
                        : (_isEditing ? 'Update' : 'Create Offer Letter'),
                    icon: _isLoading ? null : AppIcons.check,
                    onPressed: _isLoading ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaryField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: !_autoCalc,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.bodySmall,
          decoration: InputDecoration(
            prefixText: '₹ ',
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

  Widget _buildEnhancedSalarySummary() {
    final basic = double.tryParse(_basicController.text) ?? 0;
    final hra = double.tryParse(_hraController.text) ?? 0;
    final sa = double.tryParse(_saController.text) ?? 0;
    final gross = basic + hra + sa;
    final pfEmp = _isPfApplicable ? (basic * 0.12).round() : 0;
    final esicEmp = _isEsicApplicable ? (gross * 0.0075).round() : 0;
    final totalDeductions = pfEmp + esicEmp;
    final netPay = gross - totalDeductions;
    final pfEmployer = _isPfApplicable ? (basic * 0.12).round() : 0;
    final esicEmployer = _isEsicApplicable ? (gross * 0.0325).round() : 0;
    final totalEmployerDeductions = pfEmployer + esicEmployer;
    final monthlyCtc = gross + totalEmployerDeductions;

    return Column(
      children: [
        _summaryRow('Gross Salary', 'Rs ${gross.toInt()}', AppColors.primary),
        _summaryRow(
          'PF Employee (12%)',
          '-Rs $pfEmp',
          _isPfApplicable ? AppColors.warning : AppColors.textTertiary,
        ),
        _summaryRow(
          'ESIC Employee (0.75%)',
          '-Rs $esicEmp',
          _isEsicApplicable ? AppColors.warning : AppColors.textTertiary,
        ),
        _summaryRow(
          'Total Employee Deduction',
          'Rs ${totalDeductions.toInt()}',
          AppColors.warning,
        ),
        const Divider(),
        _summaryRow(
          'Net Pay in Hand',
          'Rs ${netPay.toInt()}',
          AppColors.success,
          bold: true,
        ),
        const Divider(),
        _summaryRow(
          'PF Employer (12%)',
          'Rs $pfEmployer',
          _isPfApplicable ? AppColors.info : AppColors.textTertiary,
        ),
        _summaryRow(
          'ESIC Employer (3.25%)',
          'Rs $esicEmployer',
          _isEsicApplicable ? AppColors.info : AppColors.textTertiary,
        ),
        _summaryRow(
          'Total Employer Deduction',
          'Rs ${totalEmployerDeductions.toInt()}',
          AppColors.info,
        ),
        _summaryRow(
          'Monthly CTC',
          'Rs ${monthlyCtc.toInt()}',
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildSalarySummary() {
    final ctc = double.tryParse(_ctcController.text) ?? 0;
    final basic = double.tryParse(_basicController.text) ?? 0;
    final hra = double.tryParse(_hraController.text) ?? 0;
    final sa = double.tryParse(_saController.text) ?? 0;
    final gross = basic + hra + sa;
    final pfEmp = (basic * 0.12).round();
    final esicEmp = (gross * 0.0075).round();
    final netPay = gross - pfEmp - esicEmp;

    return Column(
      children: [
        _summaryRow('Gross Salary', '₹${gross.toInt()}', AppColors.primary),
        _summaryRow('PF Employee (12%)', '-₹$pfEmp', AppColors.warning),
        _summaryRow('ESIC Employee (0.75%)', '-₹$esicEmp', AppColors.warning),
        const Divider(),
        _summaryRow(
          'Net Pay in Hand',
          '₹${netPay.toInt()}',
          AppColors.success,
          bold: true,
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

  Future<void> _handleSubmit() async {
    if (!_isEditing && !_useManualCandidate && _selectedEmployee == null) {
      setState(() => _error = 'Please select an employee');
      return;
    }
    if ((_isEditing || _useManualCandidate) &&
        _employeeNameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter candidate name');
      return;
    }
    if ((_isEditing || _useManualCandidate) &&
        _designationController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter designation');
      return;
    }
    if ((_isEditing || _useManualCandidate) &&
        _departmentController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter department');
      return;
    }
    if (_ctcController.text.isEmpty) {
      setState(() => _error = 'Please enter CTC amount');
      return;
    }

    final ctc = double.tryParse(_ctcController.text) ?? 0;
    if (ctc <= 0) {
      setState(() => _error = 'CTC must be greater than 0');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final now = DateTime.now();

      final emp = _selectedEmployee;
      final basic = double.tryParse(_basicController.text) ?? 0;
      final hra = double.tryParse(_hraController.text) ?? 0;
      final sa = double.tryParse(_saController.text) ?? 0;
      final grossSalary = basic + hra + sa;
      final generatedCode =
          'CAND-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';
      final employeeCode = (_isEditing || _useManualCandidate)
          ? (_employeeCodeController.text.trim().isEmpty
                ? generatedCode
                : _employeeCodeController.text.trim())
          : emp!.employeeCode;
      final employeeId = (_isEditing || _useManualCandidate)
          ? (widget.existingLetter?.employeeId.isNotEmpty == true
                ? widget.existingLetter!.employeeId
                : 'manual-${now.millisecondsSinceEpoch}')
          : emp!.id;
      final employeeName = (_isEditing || _useManualCandidate)
          ? _employeeNameController.text.trim()
          : emp!.fullName;
      final designation = (_isEditing || _useManualCandidate)
          ? _designationController.text.trim()
          : emp!.designation;
      final department = (_isEditing || _useManualCandidate)
          ? _departmentController.text.trim()
          : emp!.department;
      final employeeType = (_isEditing || _useManualCandidate)
          ? _manualEmployeeType
          : emp!.employeeType;

      if (_isEditing) {
        // TODO: implement update
        Navigator.pop(context, true);
      } else {
        final letter = OfferLetter(
          id: '',
          employeeId: employeeId,
          employeeCode: employeeCode,
          employeeName: employeeName,
          designation: designation,
          department: department,
          employeeType: employeeType,
          grossSalary: grossSalary,
          ctc: ctc,
          joiningDate: _joiningDate,
          status: 'draft',
          isPfApplicable: _isPfApplicable,
          isEsicApplicable: _isEsicApplicable,
          remarks: _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
          createdAt: now,
          updatedAt: now,
          createdBy: user?.userId ?? 'hr',
        );

        await ref.read(offerLetterProvider.notifier).createOfferLetter(letter);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _calculateGrossFromCtc(double ctc) {
    final employerFactor =
        1 +
        (_isPfApplicable ? 0.072 : 0) +
        (_isEsicApplicable ? 0.0325 : 0);
    return employerFactor == 0 ? ctc : ctc / employerFactor;
  }
}
