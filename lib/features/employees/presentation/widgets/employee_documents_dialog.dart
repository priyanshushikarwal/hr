import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/employee_document_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/repositories/employee_document_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/config/appwrite_config.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';

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
                              'App User not found for email: ${widget.employee.email}. Ensure the employee has registered an account.',
                            );
                          }

                          final userId =
                              userDocs.documents.first.data['userId'];

                          final repo = ref.read(notificationRepoProvider);
                          await repo.createNotification(
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
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
                      'View all uploaded files',
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
                  : ListView.builder(
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.description,
                            color: AppColors.primary,
                          ),
                          title: Text(doc.documentName),
                          subtitle: Text(
                            '${doc.documentType} • ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: AppColors.primary,
                            ),
                            tooltip: 'View / Download',
                            onPressed: () =>
                                _viewDocument(doc.fileId, doc.documentName),
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
