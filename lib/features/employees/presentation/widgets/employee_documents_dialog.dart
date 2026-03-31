import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../data/models/employee_document_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/repositories/employee_document_repository.dart';

final desktopDocRepoProvider = Provider((ref) => EmployeeDocumentRepository());
final notificationRepoProvider = Provider((ref) => NotificationRepository());

class EmployeeDocumentsDialog extends ConsumerStatefulWidget {
  final Employee employee;

  const EmployeeDocumentsDialog({super.key, required this.employee});

  @override
  ConsumerState<EmployeeDocumentsDialog> createState() =>
      _EmployeeDocumentsDialogState();
}

class _EmployeeDocumentsDialogState
    extends ConsumerState<EmployeeDocumentsDialog> {
  bool _isLoading = true;
  List<EmployeeDocument> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(desktopDocRepoProvider);
      final docs = await repo.getEmployeeDocuments(widget.employee.id);
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load documents: $e')));
      }
    }
  }

  Future<void> _viewDocument(String fileId, String fileName) async {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading document...')));

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open document: $e')));
      }
    }
  }

  Future<void> _notifyEmployee({
    required String title,
    required String message,
  }) async {
    final db = AppwriteService.instance.databases;
    final userDocs = await db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollectionId,
      queries: [
        Query.equal('email', widget.employee.email),
        Query.limit(1),
      ],
    );

    if (userDocs.documents.isEmpty) return;

    final userId = userDocs.documents.first.data['userId'];
    await ref.read(notificationRepoProvider).createNotification(
      userId: userId,
      title: title,
      message: message,
    );
  }

  Future<void> _approveDocument(EmployeeDocument doc) async {
    final currentUser = ref.read(currentUserProvider);
    try {
      await ref.read(desktopDocRepoProvider).updateApprovalStatus(
            documentId: doc.id,
            approvalStatus: 'approved',
            approvedBy: currentUser?.name ?? currentUser?.email ?? 'HR',
          );
      await _notifyEmployee(
        title: 'Document Approved',
        message: '${doc.documentType} has been approved by HR.',
      );
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve document: $e')),
        );
      }
    }
  }

  Future<void> _rejectDocument(EmployeeDocument doc) async {
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

    if (reason == null || reason.isEmpty) return;

    try {
      await ref.read(desktopDocRepoProvider).updateApprovalStatus(
            documentId: doc.id,
            approvalStatus: 'rejected',
            approvedBy: currentUser?.name ?? currentUser?.email ?? 'HR',
            rejectionReason: reason,
          );
      await _notifyEmployee(
        title: 'Document Rejected',
        message: '${doc.documentType} was rejected by HR. Reason: $reason',
      );
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject document: $e')),
        );
      }
    }
  }

  void _showRequestDialog() {
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
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Request Document'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select a document to request from the employee. They will receive a notification.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDoc,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Document Type',
                  ),
                  items: docs
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDoc = val);
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
                          final db = AppwriteService.instance.databases;
                          final userDocs = await db.listDocuments(
                            databaseId: AppwriteConfig.databaseId,
                            collectionId: AppwriteConfig.usersCollectionId,
                            queries: [
                              Query.equal('email', widget.employee.email),
                              Query.limit(1),
                            ],
                          );

                          if (userDocs.documents.isEmpty) {
                            throw Exception(
                              'App user not found for ${widget.employee.email}',
                            );
                          }

                          final userId = userDocs.documents.first.data['userId'];
                          await ref.read(notificationRepoProvider).createNotification(
                                userId: userId,
                                title: 'Document Request',
                                message:
                                    'HR has requested you to upload: $selectedDoc',
                              );

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Document request sent successfully',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setDialogState(() => isRequesting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to request document: $e'),
                              ),
                            );
                          }
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
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        height: 540,
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                      '${widget.employee.firstName}\'s Documents',
                      style: AppTypography.titleLarge,
                    ),
                    Text(
                      'Review uploaded files and approve or reject them',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_alert),
                      label: const Text('Request Doc'),
                      onPressed: _showRequestDialog,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _documents.isEmpty
                      ? const Center(child: Text('No documents uploaded yet.'))
                      : ListView.separated(
                          itemCount: _documents.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            final color = _statusColor(doc.approvalStatus);
                            return ListTile(
                              leading: const Icon(
                                Icons.description,
                                color: AppColors.primary,
                              ),
                              title: Text(doc.documentName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${doc.documentType} | ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _statusLabel(doc.approvalStatus),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (doc.isRejected &&
                                      doc.rejectionReason != null &&
                                      doc.rejectionReason!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Reason: ${doc.rejectionReason!}',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.download,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'View / Download',
                                    onPressed: () =>
                                        _viewDocument(doc.fileId, doc.documentName),
                                  ),
                                  if (!doc.isApproved)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.success,
                                      ),
                                      tooltip: 'Approve',
                                      onPressed: () => _approveDocument(doc),
                                    ),
                                  if (!doc.isRejected)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Reject',
                                      onPressed: () => _rejectDocument(doc),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
