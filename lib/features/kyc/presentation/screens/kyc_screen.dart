import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';

/// KYC & Documents Screen with Stepper UI
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  int _currentStep = 0;
  String? _selectedEmployee;

  final List<_KycStep> _steps = [
    _KycStep(
      title: 'Identity Documents',
      documents: [
        _Document(name: 'Aadhaar Card', status: 'verified', isRequired: true),
        _Document(name: 'PAN Card', status: 'verified', isRequired: true),
        _Document(name: 'Passport', status: 'pending', isRequired: false),
        _Document(
          name: 'Driving License',
          status: 'not_uploaded',
          isRequired: false,
        ),
      ],
    ),
    _KycStep(
      title: 'Address Proof',
      documents: [
        _Document(name: 'Utility Bill', status: 'verified', isRequired: true),
        _Document(
          name: 'Rent Agreement',
          status: 'not_uploaded',
          isRequired: false,
        ),
        _Document(
          name: 'Bank Statement',
          status: 'not_uploaded',
          isRequired: false,
        ),
      ],
    ),
    _KycStep(
      title: 'Educational Documents',
      documents: [
        _Document(name: '10th Marksheet', status: 'verified', isRequired: true),
        _Document(name: '12th Marksheet', status: 'verified', isRequired: true),
        _Document(
          name: 'Graduation Certificate',
          status: 'pending',
          isRequired: false,
        ),
      ],
    ),
    _KycStep(
      title: 'Employment Documents',
      documents: [
        _Document(
          name: 'Experience Letter',
          status: 'verified',
          isRequired: false,
        ),
        _Document(
          name: 'Relieving Letter',
          status: 'pending',
          isRequired: false,
        ),
        _Document(
          name: 'Previous Salary Slip',
          status: 'not_uploaded',
          isRequired: false,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'KYC & Documents',
            subtitle: 'Verify and manage employee documents',
            breadcrumbs: const ['Home', 'KYC & Documents'],
            actions: [
              SecondaryButton(
                text: 'Bulk Upload',
                icon: AppIcons.upload,
                onPressed: () {},
              ),
            ],
          ),

          // Employee Selector Card
          _buildEmployeeSelector(),

          const SizedBox(height: AppSpacing.lg),

          // KYC Stepper
          if (_selectedEmployee != null) _buildKycStepper(),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    return ContentCard(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppDropdownField<String>(
              label: 'Select Employee',
              hint: 'Search and select an employee',
              value: _selectedEmployee,
              items: const [
                'EMP001 - Rajesh Kumar',
                'EMP002 - Priya Sharma',
                'EMP003 - Amit Patel',
                'EMP004 - Sneha Reddy',
              ],
              itemLabel: (item) => item,
              onChanged: (value) => setState(() => _selectedEmployee = value),
              prefixIcon: AppIcons.employees,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // KYC Status Summary
          if (_selectedEmployee != null)
            Expanded(
              child: Row(
                children: [
                  _KycStatusChip(
                    count: 6,
                    label: 'Verified',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _KycStatusChip(
                    count: 3,
                    label: 'Pending',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _KycStatusChip(
                    count: 4,
                    label: 'Missing',
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildKycStepper() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Indicator
        SizedBox(
          width: 280,
          child: ContentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Document Categories', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.lg),
                ..._steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isActive = index == _currentStep;
                  final verifiedCount = step.documents
                      .where((d) => d.status == 'verified')
                      .length;
                  final totalRequired = step.documents
                      .where((d) => d.isRequired)
                      .length;

                  return InkWell(
                    onTap: () => setState(() => _currentStep = index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primarySurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.backgroundSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: AppTypography.labelMedium.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$verifiedCount of $totalRequired verified',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          if (verifiedCount == totalRequired)
                            Icon(
                              AppIcons.verified,
                              size: 18,
                              color: AppColors.success,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.lg),

        // Documents Grid
        Expanded(
          child: ContentCard(
            title: _steps[_currentStep].title,
            titleAction: GhostButton(
              text: 'Upload New',
              icon: AppIcons.upload,
              onPressed: () {},
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
              ),
              itemCount: _steps[_currentStep].documents.length,
              itemBuilder: (context, index) {
                final doc = _steps[_currentStep].documents[index];
                return _DocumentCard(document: doc);
              },
            ),
          ),
        ).animate().fadeIn().slideX(begin: 0.05, end: 0),
      ],
    );
  }
}

class _KycStatusChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _KycStatusChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            count.toString(),
            style: AppTypography.titleMedium.copyWith(color: color),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatefulWidget {
  final _Document document;

  const _DocumentCard({required this.document});

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _isHovered = false;

  StatusType get _statusType {
    switch (widget.document.status) {
      case 'verified':
        return StatusType.success;
      case 'pending':
        return StatusType.warning;
      default:
        return StatusType.neutral;
    }
  }

  String get _statusLabel {
    switch (widget.document.status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending Review';
      default:
        return 'Not Uploaded';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploaded = widget.document.status != 'not_uploaded';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.backgroundSecondary
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? AppColors.primarySurface
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isUploaded ? AppIcons.filePdf : AppIcons.file,
                    size: 20,
                    color: isUploaded
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.document.name,
                            style: AppTypography.labelLarge,
                          ),
                          if (widget.document.isRequired) ...[
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        label: _statusLabel,
                        type: _statusType,
                        isSmall: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_isHovered)
              Row(
                children: [
                  if (isUploaded) ...[
                    Expanded(
                      child: GhostButton(
                        text: 'View',
                        icon: AppIcons.view,
                        onPressed: () {},
                      ),
                    ),
                    Expanded(
                      child: GhostButton(
                        text: 'Replace',
                        icon: AppIcons.upload,
                        onPressed: () {},
                      ),
                    ),
                  ] else
                    Expanded(
                      child: PrimaryButton(
                        text: 'Upload',
                        icon: AppIcons.upload,
                        height: 36,
                        onPressed: () {},
                      ),
                    ),
                ],
              )
            else if (isUploaded)
              Text('Uploaded on 15 Jan 2024', style: AppTypography.caption)
            else
              Text('No file uploaded', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _KycStep {
  final String title;
  final List<_Document> documents;

  const _KycStep({required this.title, required this.documents});
}

class _Document {
  final String name;
  final String status;
  final bool isRequired;

  const _Document({
    required this.name,
    required this.status,
    required this.isRequired,
  });
}
