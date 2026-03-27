import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import '../../data/models/employee_model.dart';

/// Add Employee Drawer - Slide-in form panel
class AddEmployeeDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(Employee, String?) onSave;
  final Employee? employee; // For edit mode

  const AddEmployeeDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.employee,
  });

  @override
  State<AddEmployeeDrawer> createState() => _AddEmployeeDrawerState();
}

class _AddEmployeeDrawerState extends State<AddEmployeeDrawer> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _currentCityController = TextEditingController();
  final _currentPincodeController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();

  // Form State
  String? _employeeType;
  DateTime? _joiningDate;
  DateTime? _dateOfBirth;
  String? _gender;
  String? _maritalStatus;
  String? _currentState;

  final List<_StepData> _steps = const [
    _StepData(title: 'Basic Info', icon: AppIcons.user),
    _StepData(title: 'Work Details', icon: AppIcons.briefcase),
    _StepData(title: 'Contact', icon: AppIcons.phone),
    _StepData(title: 'Documents', icon: AppIcons.documents),
  ];

  @override
  void initState() {
    super.initState();
    _populateForm(widget.employee);
  }

  @override
  void didUpdateWidget(covariant AddEmployeeDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee?.id != widget.employee?.id) {
      _populateForm(widget.employee);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _bankNameController.dispose();
    _currentAddressController.dispose();
    _currentCityController.dispose();
    _currentPincodeController.dispose();
    _bankAccountNumberController.dispose();
    _ifscCodeController.dispose();
    _panNumberController.dispose();
    _aadhaarNumberController.dispose();
    super.dispose();
  }

  void _populateForm(Employee? employee) {
    _firstNameController.text = employee?.firstName ?? '';
    _lastNameController.text = employee?.lastName ?? '';
    _emailController.text = employee?.email ?? '';
    _phoneController.text = employee?.phone ?? '';
    _alternatePhoneController.text = employee?.alternatePhone ?? '';
    _passwordController.clear();
    _departmentController.text = employee?.department ?? '';
    _designationController.text = employee?.designation ?? '';
    _bankNameController.text = employee?.bankName ?? '';
    _currentAddressController.text = employee?.currentAddress ?? '';
    _currentCityController.text = employee?.currentCity ?? '';
    _currentPincodeController.text = employee?.currentPincode ?? '';
    _bankAccountNumberController.text = employee?.bankAccountNumber ?? '';
    _ifscCodeController.text = employee?.ifscCode ?? '';
    _panNumberController.text = employee?.panNumber ?? '';
    _aadhaarNumberController.text = employee?.aadhaarNumber ?? '';

    _employeeType = employee?.employeeType;
    _joiningDate = employee?.joiningDate;
    _dateOfBirth = employee?.dateOfBirth;
    _gender = employee?.gender;
    _maritalStatus = employee?.maritalStatus;
    _currentState = employee?.currentState;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Row(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () {}, // Prevent tap-through
              child: Container(
                width: AppSpacing.drawerWidthLarge,
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(-4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Progress Steps
                    _buildStepIndicator(),

                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.drawerPadding),
                        child: Form(key: _formKey, child: _buildCurrentStep()),
                      ),
                    ),

                    // Footer Actions
                    _buildFooter(),
                  ],
                ),
              ).animate().slideX(begin: 1, end: 0, duration: 300.ms),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.drawerPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              AppIcons.userAdd,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee != null
                      ? 'Edit Employee'
                      : 'Add New Employee',
                  style: AppTypography.headlineSmall,
                ),
                Text(
                  'Fill in the details to ${widget.employee != null ? "update" : "add"} employee',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          AppIconButton(icon: AppIcons.close, onPressed: widget.onClose),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.drawerPadding,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: _steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step Circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : isCompleted
                        ? AppColors.success
                        : AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isCompleted
                          ? Colors.transparent
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.title,
                    style: AppTypography.labelMedium.copyWith(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Connector Line
                if (index < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isCompleted ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildWorkDetailsStep();
      case 2:
        return _buildContactStep();
      case 3:
        return _buildDocumentsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Information', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        // Name Row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'First Name',
                hint: 'Enter first name',
                controller: _firstNameController,
                isRequired: true,
                prefixIcon: AppIcons.user,
                validator: _requiredValidator,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Last Name',
                hint: 'Enter last name',
                controller: _lastNameController,
                isRequired: true,
                validator: _requiredValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Employee Type
        AppDropdownField<String>(
          label: 'Employee Type',
          hint: 'Select employee type',
          value: _employeeType,
          items: const ['office', 'factory'],
          itemLabel: (item) =>
              item == 'office' ? 'Office Employee' : 'Factory Employee',
          onChanged: (value) => setState(() => _employeeType = value),
          isRequired: true,
          prefixIcon: AppIcons.employees,
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Date of Birth
        Row(
          children: [
            Expanded(
              child: AppDateField(
                label: 'Date of Birth',
                hint: 'Select date',
                value: _dateOfBirth,
                lastDate: DateTime.now().subtract(
                  const Duration(days: 6570),
                ), // 18 years
                onChanged: (date) => setState(() => _dateOfBirth = date),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppDropdownField<String>(
                label: 'Gender',
                hint: 'Select gender',
                value: _gender,
                items: AppConstants.genders,
                itemLabel: (item) => item,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Marital Status
        AppDropdownField<String>(
          label: 'Marital Status',
          hint: 'Select marital status',
          value: _maritalStatus,
          items: AppConstants.maritalStatus,
          itemLabel: (item) => item,
          onChanged: (value) => setState(() => _maritalStatus = value),
        ),
      ],
    );
  }

  Widget _buildWorkDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work Information', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        // Department
        AppTextField(
          label: 'Department',
          hint: 'Enter department',
          controller: _departmentController,
          isRequired: true,
          prefixIcon: AppIcons.department,
          validator: _requiredValidator,
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Designation
        AppTextField(
          label: 'Designation',
          hint: 'Enter designation',
          controller: _designationController,
          isRequired: true,
          prefixIcon: AppIcons.designation,
          validator: _requiredValidator,
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Joining Date
        AppDateField(
          label: 'Joining Date',
          hint: 'Select joining date',
          value: _joiningDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onChanged: (date) => setState(() => _joiningDate = date),
          isRequired: true,
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Employee ID Preview
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(AppIcons.info, size: 20, color: AppColors.info),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee ID will be auto-generated',
                      style: AppTypography.labelMedium,
                    ),
                    Text(
                      'Format: EMP-YYYY-XXXX (e.g., EMP-2024-0011)',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        // Email
        AppTextField(
          label: 'Email Address',
          hint: 'Enter email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
          prefixIcon: AppIcons.email,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'This field is required';
            if (!text.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Appwrite Initial Password
        AppTextField(
          label: 'Initial App Password',
          hint: 'Enter password for mobile app login',
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          isRequired:
              widget.employee == null, // password required for new users
          obscureText: true,
          prefixIcon: AppIcons.lock,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (widget.employee == null && text.isEmpty) {
              return 'This field is required';
            }
            if (text.isNotEmpty && text.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        if (widget.employee == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Required for the employee to login to the mobile app (min 8 characters).',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Phone Numbers
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Phone Number',
                hint: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                isRequired: true,
                prefixIcon: AppIcons.phone,
                validator: _requiredValidator,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Alternate Phone',
                hint: 'Enter alternate number',
                controller: _alternatePhoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: AppIcons.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.formSectionSpacing),

        Text('Address', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        // Current Address
        AppTextField(
          label: 'Current Address',
          hint: 'Enter current address',
          controller: _currentAddressController,
          maxLines: 3,
          prefixIcon: AppIcons.address,
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // City, State, Pincode
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'City',
                hint: 'Enter city',
                controller: _currentCityController,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppDropdownField<String>(
                label: 'State',
                hint: 'Select state',
                value: _currentState,
                items: AppConstants.indianStates,
                itemLabel: (item) => item,
                onChanged: (value) => setState(() => _currentState = value),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Pincode',
                hint: 'Enter pincode',
                controller: _currentPincodeController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank Details', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        // Bank Name
        AppTextField(
          label: 'Bank Name',
          hint: 'Enter bank name',
          controller: _bankNameController,
          prefixIcon: AppIcons.bank,
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // Account Number & IFSC
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'Account Number',
                hint: 'Enter account number',
                controller: _bankAccountNumberController,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'IFSC Code',
                hint: 'Enter IFSC',
                controller: _ifscCodeController,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.formSectionSpacing),

        Text('Statutory Details', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        // PAN & Aadhaar
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'PAN Number',
                hint: 'Enter PAN number',
                controller: _panNumberController,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Aadhaar Number',
                hint: 'Enter Aadhaar number',
                controller: _aadhaarNumberController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.formFieldSpacing),

        // PF & ESIC Note
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.infoSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(AppIcons.info, size: 20, color: AppColors.info),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'PF and ESIC will be activated automatically after 3 months of joining as per company policy.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.infoDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.drawerPadding),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            SecondaryButton(
              text: 'Previous',
              icon: AppIcons.arrowLeft,
              onPressed: () {
                setState(() => _currentStep--);
              },
            ),
          const Spacer(),
          SecondaryButton(text: 'Cancel', onPressed: widget.onClose),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(
            text: _currentStep < _steps.length - 1 ? 'Next' : 'Save Employee',
            icon: _currentStep < _steps.length - 1
                ? AppIcons.arrowRight
                : AppIcons.save,
            onPressed: () {
              if (_currentStep < _steps.length - 1) {
                setState(() => _currentStep++);
              } else {
                if (_formKey.currentState?.validate() ?? false) {
                  final newEmployee = Employee(
                    id:
                        widget.employee?.id ??
                        '', // Appwrite will generate an ID on creation if empty
                    employeeCode:
                        widget.employee?.employeeCode ??
                        'EMP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    firstName: _firstNameController.text.trim(),
                    lastName: _lastNameController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim(),
                    alternatePhone:
                        _alternatePhoneController.text.trim().isEmpty
                        ? null
                        : _alternatePhoneController.text.trim(),
                    employeeType: _employeeType ?? 'office',
                    department: _departmentController.text.trim().isEmpty
                        ? 'General'
                        : _departmentController.text.trim(),
                    designation: _designationController.text.trim().isEmpty
                        ? 'Employee'
                        : _designationController.text.trim(),
                    bankName: _bankNameController.text.trim().isEmpty
                        ? null
                        : _bankNameController.text.trim(),
                    bankAccountNumber:
                        _bankAccountNumberController.text.trim().isEmpty
                        ? null
                        : _bankAccountNumberController.text.trim(),
                    ifscCode: _ifscCodeController.text.trim().isEmpty
                        ? null
                        : _ifscCodeController.text.trim(),
                    panNumber: _panNumberController.text.trim().isEmpty
                        ? null
                        : _panNumberController.text.trim(),
                    aadhaarNumber: _aadhaarNumberController.text.trim().isEmpty
                        ? null
                        : _aadhaarNumberController.text.trim(),
                    joiningDate: _joiningDate ?? DateTime.now(),
                    dateOfBirth: _dateOfBirth,
                    gender: _gender,
                    maritalStatus: _maritalStatus,
                    currentAddress:
                        _currentAddressController.text.trim().isEmpty
                        ? null
                        : _currentAddressController.text.trim(),
                    currentCity: _currentCityController.text.trim().isEmpty
                        ? null
                        : _currentCityController.text.trim(),
                    currentState: _currentState,
                    currentPincode:
                        _currentPincodeController.text.trim().isEmpty
                        ? null
                        : _currentPincodeController.text.trim(),
                    status: widget.employee?.status ?? 'Active',
                    createdAt: widget.employee?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                    isPfApplicable: false,
                    isEsicApplicable: false,
                  );
                  final pwd = _passwordController.text.trim();
                  widget.onSave(newEmployee, pwd.isEmpty ? null : pwd);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}

class _StepData {
  final String title;
  final IconData icon;

  const _StepData({required this.title, required this.icon});
}
