import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/appwrite_config.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/header.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../employees/data/models/employee_document_model.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/repositories/employee_document_repository.dart';
import '../../../employees/domain/providers/employee_providers.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

final kycDocRepoProvider = Provider((ref) => EmployeeDocumentRepository());
final kycNotificationRepoProvider = Provider((ref) => NotificationRepository());

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
  bool _showPendingOnly = false;
  String? _busyDocumentId;
  List<EmployeeDocument> _documents = [];

  final List<String> _identityDocs = const [
    'Aadhaar Card',
    'PAN Card',
    'Passport',
    'Driving License',
    'Voter ID',
  ];
  final List<String> _addressDocs = const [
    'Utility Bill',
    'Rent Agreement',
    'Bank Statement',
    'Bank Passbook',
  ];
  final List<String> _eduDocs = const [
    '10th Marksheet',
    '12th Marksheet',
    'Graduation Certificate',
    'Post Graduation Certificate',
  ];
  final List<String> _empDocs = const [
    'Experience Letter',
    'Relieving Letter',
    'Salary Slip',
    'Previous Salary Slip',
    'Offer Letter',
    'Resume',
  ];

  Future<void> _loadDocuments(Employee employee) async {
    setState(() => _isLoading = true);
    try {
      final docs = await ref.read(kycDocRepoProvider).getEmployeeDocuments(employee.id);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _isLoading = false;
        _currentStep = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load documents: $e')));
    }
  }

  Future<void> _viewDocument(EmployeeDocument document) async {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading document...')));

      final bytes = await AppwriteService.instance.storage.getFileDownload(
        bucketId: AppwriteConfig.employeeDocumentsBucketId,
        fileId: document.fileId,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${document.documentName}');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open document: $e')));
    }
  }

  Future<void> _notifyEmployee({
    required String title,
    required String message,
  }) async {
    final employee = _selectedEmployee;
    if (employee == null) return;

    final userDocs = await AppwriteService.instance.databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollectionId,
      queries: [
        Query.equal('email', employee.email),
        Query.limit(1),
      ],
    );

    if (userDocs.documents.isEmpty) return;

    final userId = userDocs.documents.first.data['userId'];
    await ref.read(kycNotificationRepoProvider).createNotification(
      userId: userId,
      title: title,
      message: message,
    );
  }

  Future<void> _approveDocument(EmployeeDocument document) async {
    final currentUser = ref.read(currentUserProvider);
    setState(() => _busyDocumentId = document.id);
    try {
      await ref.read(kycDocRepoProvider).updateApprovalStatus(
            documentId: document.id,
            approvalStatus: 'approved',
            approvedBy: currentUser?.name ?? currentUser?.email ?? 'HR',
          );
      await _notifyEmployee(
        title: 'Document Approved',
        message: '${document.documentType} has been approved by HR.',
      );
      if (_selectedEmployee != null) {
        await _loadDocuments(_selectedEmployee!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document approved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve document: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyDocumentId = null);
      }
    }
  }

  Future<void> _rejectDocument(EmployeeDocument document) async {
    final reasonController = TextEditingController();
    final currentUser = ref.read(currentUserProvider);

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Reason',
            hintText: 'Enter rejection reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) {
      reasonController.dispose();
      return;
    }

    setState(() => _busyDocumentId = document.id);
    try {
      await ref.read(kycDocRepoProvider).updateApprovalStatus(
            documentId: document.id,
            approvalStatus: 'rejected',
            approvedBy: currentUser?.name ?? currentUser?.email ?? 'HR',
            rejectionReason: reason,
          );
      await _notifyEmployee(
        title: 'Document Rejected',
        message: '${document.documentType} was rejected by HR. Reason: $reason',
      );
      if (_selectedEmployee != null) {
        await _loadDocuments(_selectedEmployee!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document rejected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject document: $e')),
      );
    } finally {
      reasonController.dispose();
      if (mounted) {
        setState(() => _busyDocumentId = null);
      }
    }
  }

  void _showRequestDialog() {
    if (_selectedEmployee == null) return;

    String selectedDoc = 'Aadhaar Card';
    final docs = [
      'Aadhaar Card',
      'PAN Card',
      'Passport',
      'Driving License',
      'Voter ID',
      'Utility Bill',
      'Rent Agreement',
      'Bank Statement',
      'Bank Passbook',
      '10th Marksheet',
      '12th Marksheet',
      'Graduation Certificate',
      'Post Graduation Certificate',
      'Experience Letter',
      'Relieving Letter',
      'Salary Slip',
      'Previous Salary Slip',
      'Offer Letter',
      'Resume',
      'Other',
    ];
    bool isRequesting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send a document request to ${_selectedEmployee!.firstName}.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDoc,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Document Type',
                ),
                items: docs
                    .map((doc) => DropdownMenuItem(value: doc, child: Text(doc)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedDoc = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isRequesting
                  ? null
                  : () async {
                      setDialogState(() => isRequesting = true);
                      try {
                        await _notifyEmployee(
                          title: 'Document Request',
                          message: 'HR has requested you to upload: $selectedDoc',
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document request sent successfully'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setDialogState(() => isRequesting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to request document: $e'),
                          ),
                        );
                      }
                    },
              child: isRequesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  List<_KycStep> _getSteps() {
    List<_Document> mapCategory(List<String> categoryTypes, List<String> requiredTypes) {
      final items = <_Document>[];

      for (final type in categoryTypes) {
        final matches = _documents.where((doc) => doc.documentType == type).toList();
        if (matches.isEmpty) {
          items.add(
            _Document.placeholder(
              name: type,
              type: type,
              isRequired: requiredTypes.contains(type),
            ),
          );
          continue;
        }

        for (final doc in matches) {
          items.add(
            _Document.fromEmployeeDocument(
              doc,
              isRequired: requiredTypes.contains(type),
            ),
          );
        }
      }

      return items;
    }

    final mainTypes = [
      ..._identityDocs,
      ..._addressDocs,
      ..._eduDocs,
      ..._empDocs,
    ];

    final steps = [
      _KycStep(
        title: 'Identity Documents',
        documents: mapCategory(_identityDocs, const ['Aadhaar Card', 'PAN Card']),
      ),
      _KycStep(
        title: 'Address Proof',
        documents: mapCategory(_addressDocs, const ['Utility Bill']),
      ),
      _KycStep(
        title: 'Educational Documents',
        documents: mapCategory(_eduDocs, const ['10th Marksheet', '12th Marksheet']),
      ),
      _KycStep(
        title: 'Employment Documents',
        documents: mapCategory(_empDocs, const []),
      ),
    ];

    final otherDocs = _documents
        .where((doc) => !mainTypes.contains(doc.documentType))
        .map((doc) => _Document.fromEmployeeDocument(doc, isRequired: false))
        .toList();
    if (otherDocs.isNotEmpty) {
      steps.add(_KycStep(title: 'Other Documents', documents: otherDocs));
    }

    return steps;
  }

  _KycCounts _buildCounts(List<_KycStep> steps) {
    int approved = 0;
    int pending = 0;
    int rejected = 0;
    int missingRequired = 0;

    for (final step in steps) {
      for (final document in step.documents) {
        switch (document.status) {
          case 'approved':
            approved++;
            break;
          case 'pending':
            pending++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'not_uploaded':
            if (document.isRequired) {
              missingRequired++;
            }
            break;
        }
      }
    }

    return _KycCounts(
      approved: approved,
      pending: pending,
      rejected: rejected,
      missingRequired: missingRequired,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'KYC & Documents',
            subtitle: 'Review employee uploads, approve or reject documents, and track missing KYC items',
            breadcrumbs: const ['Home', 'KYC & Documents'],
            actions: [
              SecondaryButton(
                text: 'Request Document',
                icon: AppIcons.notification,
                onPressed: _selectedEmployee == null ? null : _showRequestDialog,
              ),
            ],
          ),
          _buildEmployeeSelector(),
          const SizedBox(height: AppSpacing.lg),
          if (_selectedEmployee != null) _buildKycWorkspace(),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    final employeesState = ref.watch(employeeListProvider);
    final activeEmployees = employeesState.employees.where((employee) => employee.isActive).toList();
    final dropdownItems = activeEmployees
        .map((employee) => '${employee.employeeCode} - ${employee.firstName} ${employee.lastName}')
        .toList();

    if (_selectedEmployeeLabel != null && !dropdownItems.contains(_selectedEmployeeLabel)) {
      _selectedEmployeeLabel = null;
      _selectedEmployee = null;
      _documents = [];
    }

    final steps = _selectedEmployee != null ? _getSteps() : const <_KycStep>[];
    final counts = _buildCounts(steps);

    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    if (value == null) return;
                    final selected = activeEmployees.firstWhere(
                      (employee) =>
                          '${employee.employeeCode} - ${employee.firstName} ${employee.lastName}' == value,
                    );
                    setState(() {
                      _selectedEmployeeLabel = value;
                      _selectedEmployee = selected;
                      _showPendingOnly = false;
                    });
                    _loadDocuments(selected);
                  },
                  prefixIcon: AppIcons.employees,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  alignment: WrapAlignment.end,
                  children: [
                    _KycStatusChip(
                      count: counts.approved,
                      label: 'Approved',
                      color: AppColors.success,
                    ),
                    _KycStatusChip(
                      count: counts.pending,
                      label: 'Pending',
                      color: AppColors.warning,
                    ),
                    _KycStatusChip(
                      count: counts.rejected,
                      label: 'Rejected',
                      color: AppColors.error,
                    ),
                    _KycStatusChip(
                      count: counts.missingRequired,
                      label: 'Missing Req.',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedEmployee != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                StatusBadge(
                  label: _showPendingOnly ? 'Showing Pending Only' : 'Showing All Documents',
                  type: _showPendingOnly ? StatusType.warning : StatusType.info,
                ),
                const Spacer(),
                GhostButton(
                  text: _showPendingOnly ? 'Show All' : 'Pending Only',
                  icon: _showPendingOnly ? AppIcons.list : AppIcons.pending,
                  onPressed: () => setState(() => _showPendingOnly = !_showPendingOnly),
                ),
                const SizedBox(width: AppSpacing.sm),
                GhostButton(
                  text: 'Refresh',
                  icon: AppIcons.refresh,
                  onPressed: _selectedEmployee == null ? null : () => _loadDocuments(_selectedEmployee!),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildKycWorkspace() {
    final steps = _getSteps();
    if (_currentStep >= steps.length) {
      _currentStep = 0;
    }

    final activeStep = steps[_currentStep];
    final visibleDocuments = _showPendingOnly
        ? activeStep.documents.where((doc) => doc.status == 'pending').toList()
        : activeStep.documents;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
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
                  final approvedCount =
                      step.documents.where((doc) => doc.status == 'approved').length;
                  final pendingCount =
                      step.documents.where((doc) => doc.status == 'pending').length;
                  final requiredCount = step.documents.where((doc) => doc.isRequired).length;
                  final requiredApprovedCount = step.documents
                      .where((doc) => doc.isRequired && doc.status == 'approved')
                      .length;
                  final allRequiredApproved =
                      requiredCount == 0 || requiredApprovedCount == requiredCount;

                  return InkWell(
                    onTap: () => setState(() => _currentStep = index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primarySurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? AppColors.primary : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : AppColors.backgroundSecondary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: AppTypography.labelMedium.copyWith(
                                color: isActive ? Colors.white : AppColors.textSecondary,
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
                                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$approvedCount approved, $pendingCount pending',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          if (allRequiredApproved && requiredCount > 0)
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
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ContentCard(
                  title: activeStep.title,
                  titleAction: GhostButton(
                    text: 'Pending Only',
                    icon: AppIcons.pending,
                    color: _showPendingOnly ? AppColors.warning : AppColors.primary,
                    onPressed: () => setState(() => _showPendingOnly = !_showPendingOnly),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showPendingOnly
                            ? 'Only pending reviews are shown in this category.'
                            : 'Uploaded, missing, rejected, and approved documents are all visible here.',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      visibleDocuments.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.55,
                              ),
                              itemCount: visibleDocuments.length,
                              itemBuilder: (context, index) {
                                final document = visibleDocuments[index];
                                final isBusy = _busyDocumentId == document.id;
                                return _DocumentCard(
                                  document: document,
                                  isBusy: isBusy,
                                  onView: document.employeeDocument == null
                                      ? null
                                      : () => _viewDocument(document.employeeDocument!),
                                  onApprove: document.employeeDocument == null || document.isApproved
                                      ? null
                                      : () => _approveDocument(document.employeeDocument!),
                                  onReject: document.employeeDocument == null || document.isRejected
                                      ? null
                                      : () => _rejectDocument(document.employeeDocument!),
                                );
                              },
                            ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: 0.05, end: 0),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(AppIcons.pending, color: AppColors.warning, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text('No pending documents in this category', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Switch to "Show All" to review approved, rejected, or missing items as well.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: AppTypography.titleMedium.copyWith(color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatefulWidget {
  final _Document document;
  final bool isBusy;
  final VoidCallback? onView;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _DocumentCard({
    required this.document,
    required this.isBusy,
    this.onView,
    this.onApprove,
    this.onReject,
  });

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _isHovered = false;

  StatusType get _statusType {
    switch (widget.document.status) {
      case 'approved':
        return StatusType.success;
      case 'pending':
        return StatusType.warning;
      case 'rejected':
        return StatusType.error;
      default:
        return StatusType.neutral;
    }
  }

  String get _statusLabel {
    switch (widget.document.status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Not Uploaded';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploaded = widget.document.employeeDocument != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.backgroundSecondary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? AppColors.primary.withOpacity(0.25) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUploaded ? AppColors.primarySurface : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isUploaded ? AppIcons.filePdf : AppIcons.file,
                    size: 20,
                    color: isUploaded ? AppColors.primary : AppColors.textTertiary,
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
                          if (widget.document.isRequired)
                            Text(
                              '*',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.error,
                              ),
                            ),
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
            const SizedBox(height: 10),
            Text(
              widget.document.name,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.document.reviewMeta != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.document.reviewMeta!,
                style: AppTypography.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (widget.document.rejectionReason != null &&
                widget.document.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${widget.document.rejectionReason!}',
                style: AppTypography.caption.copyWith(color: AppColors.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            if (!isUploaded) ...[
              Text('Employee has not uploaded this document yet.', style: AppTypography.caption),
            ] else if (widget.isBusy) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GhostButton(
                    text: 'View',
                    icon: AppIcons.view,
                    onPressed: widget.onView,
                  ),
                  if (!widget.document.isApproved)
                    GhostButton(
                      text: 'Approve',
                      icon: AppIcons.approve,
                      color: AppColors.success,
                      onPressed: widget.onApprove,
                    ),
                  if (!widget.document.isRejected)
                    GhostButton(
                      text: 'Reject',
                      icon: AppIcons.reject,
                      color: AppColors.error,
                      onPressed: widget.onReject,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KycStep {
  final String title;
  final List<_Document> documents;

  const _KycStep({
    required this.title,
    required this.documents,
  });
}

class _KycCounts {
  final int approved;
  final int pending;
  final int rejected;
  final int missingRequired;

  const _KycCounts({
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.missingRequired,
  });
}

class _Document {
  final String id;
  final String name;
  final String type;
  final String status;
  final bool isRequired;
  final String? rejectionReason;
  final String? reviewMeta;
  final EmployeeDocument? employeeDocument;

  const _Document({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.isRequired,
    required this.employeeDocument,
    this.rejectionReason,
    this.reviewMeta,
  });

  factory _Document.fromEmployeeDocument(
    EmployeeDocument document, {
    required bool isRequired,
  }) {
    String? reviewMeta;
    if (document.reviewedAt != null && document.approvedBy != null && document.approvedBy!.isNotEmpty) {
      final reviewedAt = document.reviewedAt!;
      final period = reviewedAt.hour >= 12 ? 'PM' : 'AM';
      final hour = reviewedAt.hour % 12 == 0 ? 12 : reviewedAt.hour % 12;
      final minute = reviewedAt.minute.toString().padLeft(2, '0');
      reviewMeta = 'Reviewed by ${document.approvedBy} on ${reviewedAt.day}/${reviewedAt.month}/${reviewedAt.year} $hour:$minute $period';
    }

    return _Document(
      id: document.id,
      name: document.documentName,
      type: document.documentType,
      status: document.approvalStatus,
      isRequired: isRequired,
      employeeDocument: document,
      rejectionReason: document.rejectionReason,
      reviewMeta: reviewMeta,
    );
  }

  factory _Document.placeholder({
    required String name,
    required String type,
    required bool isRequired,
  }) {
    return _Document(
      id: type,
      name: name,
      type: type,
      status: 'not_uploaded',
      isRequired: isRequired,
      employeeDocument: null,
    );
  }

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
