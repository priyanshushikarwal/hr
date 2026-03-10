import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../../employees/data/models/employee_document_model.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/repositories/employee_document_repository.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/config/appwrite_config.dart';

final kycDocRepoProvider = Provider((ref) => EmployeeDocumentRepository());

/// KYC & Documents Screen with Stepper UI
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  int _currentStep = 0;
  String? _selectedEmployeeLabel;
  Employee? _selectedEmployee;

  bool _isLoading = false;
  List<EmployeeDocument> _documents = [];

  final List<String> _identityDocs = ['Aadhaar Card', 'PAN Card', 'Passport', 'Driving License', 'Voter ID'];
  final List<String> _addressDocs = ['Utility Bill', 'Rent Agreement', 'Bank Statement', 'Bank Passbook'];
  final List<String> _eduDocs = ['10th Marksheet', '12th Marksheet', 'Graduation Certificate', 'Post Graduation Certificate'];
  final List<String> _empDocs = ['Experience Letter', 'Relieving Letter', 'Salary Slip', 'Previous Salary Slip', 'Offer Letter', 'Resume'];

  Future<void> _loadDocuments(Employee employee) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final repo = ref.read(kycDocRepoProvider);
      final docs = await repo.getEmployeeDocuments(employee.id);
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load documents: $e')));
      }
    }
  }

  Future<void> _viewDocument(String fileId, String fileName) async {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading document...')));

      final storage = AppwriteService.instance.storage;
      final bytes = await storage.getFileDownload(
        bucketId: AppwriteConfig.employeeDocumentsBucketId,
        fileId: fileId,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open document: $e')));
      }
    }
  }

  List<_KycStep> _getSteps() {
    List<_Document> getDocsForCategory(List<String> docTypes, List<String> requiredTypes) {
      final result = <_Document>[];
      for (final type in docTypes) {
        final docsForType = _documents.where((d) => d.documentType == type).toList();
        if (docsForType.isNotEmpty) {
           for (final doc in docsForType) {
             result.add(_Document(name: doc.documentName, type: doc.documentType, status: 'verified', isRequired: requiredTypes.contains(type), fileId: doc.fileId));
           }
        } else {
           result.add(_Document(name: type, type: type, status: 'not_uploaded', isRequired: requiredTypes.contains(type), fileId: null));
        }
      }
      return result;
    }

    final identityDocuments = getDocsForCategory(_identityDocs, ['Aadhaar Card', 'PAN Card']);
    final addressDocuments = getDocsForCategory(_addressDocs, ['Utility Bill']);
    final eduDocuments = getDocsForCategory(_eduDocs, ['10th Marksheet', '12th Marksheet']);
    final empDocuments = getDocsForCategory(_empDocs, []);

    // Also collect "Other" documents
    final mainTypes = [..._identityDocs, ..._addressDocs, ..._eduDocs, ..._empDocs];
    final otherDocs = _documents.where((d) => !mainTypes.contains(d.documentType)).toList();
    final otherDocuments = otherDocs.map((d) => _Document(name: d.documentName, type: d.documentType, status: 'verified', isRequired: false, fileId: d.fileId)).toList();
    
    final steps = [
      _KycStep(title: 'Identity Documents', documents: identityDocuments),
      _KycStep(title: 'Address Proof', documents: addressDocuments),
      _KycStep(title: 'Educational Documents', documents: eduDocuments),
      _KycStep(title: 'Employment Documents', documents: empDocuments),
    ];
    if (otherDocuments.isNotEmpty) {
      steps.add(_KycStep(title: 'Other Documents', documents: otherDocuments));
    }
    return steps;
  }

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
    final employeesState = ref.watch(employeeListProvider);
    final activeEmployees = employeesState.employees
        .where((e) => e.isActive)
        .toList();
    final dropdownItems = activeEmployees
        .map((e) => '${e.employeeCode} - ${e.firstName} ${e.lastName}')
        .toList();

    if (_selectedEmployeeLabel != null &&
        !dropdownItems.contains(_selectedEmployeeLabel)) {
      _selectedEmployeeLabel = null;
      _selectedEmployee = null;
      _documents = [];
    }

    // Stats
    final steps = _selectedEmployee != null ? _getSteps() : <_KycStep>[];
    int verifiedCount = 0;
    int pendingCount = 0; // if we want to add later
    int missingCount = 0;
    
    if (_selectedEmployee != null) {
       for (var step in steps) {
         for (var doc in step.documents) {
           if (doc.status == 'verified') {
             verifiedCount++;
           } else if (doc.isRequired && doc.status == 'not_uploaded') {
             missingCount++;
           }
         }
       }
    }

    return ContentCard(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppDropdownField<String>(
              label: 'Select Employee',
              hint: 'Search and select an employee',
              value: _selectedEmployeeLabel,
              items: dropdownItems,
              itemLabel: (item) => item,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedEmployeeLabel = value);
                  final matchedEmp = activeEmployees.firstWhere((e) => '${e.employeeCode} - ${e.firstName} ${e.lastName}' == value);
                  setState(() => _selectedEmployee = matchedEmp);
                  _loadDocuments(matchedEmp);
                }
              },
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
                    count: verifiedCount,
                    label: 'Verified',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _KycStatusChip(
                    count: pendingCount,
                    label: 'Pending',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _KycStatusChip(
                    count: missingCount,
                    label: 'Missing Rq.',
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
    final steps = _getSteps();
    if (_currentStep >= steps.length) {
      _currentStep = 0;
    }

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
                ...steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isActive = index == _currentStep;
                  final verifiedCount = step.documents
                      .where((d) => d.status == 'verified')
                      .length;
                  final totalRequired = step.documents
                      .where((d) => d.isRequired)
                      .length;
                  
                  final isAllRequiredVerified = totalRequired == 0 || step.documents.where((d) => d.isRequired && d.status == 'verified').length == totalRequired;

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
                                  '$verifiedCount uploaded${totalRequired > 0 ? ', $totalRequired required' : ''}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          if (isAllRequiredVerified && totalRequired > 0)
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ContentCard(
            title: steps[_currentStep].title,
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
              itemCount: steps[_currentStep].documents.length,
              itemBuilder: (context, index) {
                final doc = steps[_currentStep].documents[index];
                return _DocumentCard(
                  document: doc,
                  onView: doc.fileId != null ? () => _viewDocument(doc.fileId!, doc.name) : null,
                );
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
  final VoidCallback? onView;

  const _DocumentCard({required this.document, this.onView});

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
                          Expanded(
                            child: Text(
                              widget.document.type,
                              style: AppTypography.labelLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                        onPressed: widget.onView ?? () {},
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
              Text(
                widget.document.name,
                style: AppTypography.caption,
                overflow: TextOverflow.ellipsis,
              )
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
  final String type;
  final String status;
  final bool isRequired;
  final String? fileId;

  const _Document({
    required this.name,
    required this.type,
    required this.status,
    required this.isRequired,
    this.fileId,
  });
}
