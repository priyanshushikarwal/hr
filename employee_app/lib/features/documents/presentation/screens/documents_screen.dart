import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/config/appwrite_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/employee_document_model.dart';
import '../../domain/providers/document_providers.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  Future<void> _pickAndUploadDocument({EmployeeDocument? replaceTarget}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final fileSize = file.size;

      if (fileSize > 50000000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 50MB'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      String finalPath = file.path!;
      final ext = file.extension?.toLowerCase() ?? '';

      // Compress if it is an image
      if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
        try {
          final tmpDir = Directory.systemTemp;
          final targetPath =
              '${tmpDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$ext';
              
          CompressFormat format = CompressFormat.jpeg;
          if (ext == 'png') {
            format = CompressFormat.png;
          }

          final result = await FlutterImageCompress.compressAndGetFile(
            file.path!,
            targetPath,
            quality: 50,
            format: format,
          );
          if (result != null) {
            finalPath = result.path;
          }
        } catch (e) {
          debugPrint('Compression failed or not supported: $e');
        }
      }

      _showTypeSelectionDialog(
        finalPath,
        file.name,
        replaceTarget: replaceTarget,
      );
    }
  }

  void _showTypeSelectionDialog(
    String filePath,
    String fileName, {
    EmployeeDocument? replaceTarget,
  }) {
    String selectedType = replaceTarget?.documentType ?? 'Other';
    final types = [
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          replaceTarget == null ? 'Select Document Type' : 'Replace Document',
        ),
        content: StatefulBuilder(
          builder: (context, setState) => DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Document Type',
            ),
            items: types
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedType = val);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (replaceTarget == null) {
                ref
                    .read(documentNotifierProvider.notifier)
                    .uploadDocument(
                      filePath: filePath,
                      fileName: fileName,
                      documentType: selectedType,
                    );
              } else {
                ref
                    .read(documentNotifierProvider.notifier)
                    .replaceDocument(
                      documentId: replaceTarget.id,
                      previousFileId: replaceTarget.fileId,
                      filePath: filePath,
                      fileName: fileName,
                      documentType: selectedType,
                    );
              }
            },
            child: Text(replaceTarget == null ? 'Upload' : 'Replace'),
          ),
        ],
      ),
    );
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
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open document: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(employeeDocumentsProvider);
    final uploadState = ref.watch(documentNotifierProvider);

    ref.listen<AsyncValue<void>>(documentNotifierProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous?.isLoading == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document uploaded successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        error: (error, _) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Documents'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: uploadState.isLoading ? null : _pickAndUploadDocument,
        icon: uploadState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload_file),
        label: Text(uploadState.isLoading ? 'Uploading...' : 'Upload'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: documentsState.when(
        data: (documents) {
          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(employeeDocumentsProvider);
                await ref.read(employeeDocumentsProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No documents uploaded yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(employeeDocumentsProvider);
              await ref.read(employeeDocumentsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: const Icon(
                        Icons.description,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      doc.documentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                doc.documentType,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM yy').format(doc.uploadedAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ApprovalStatusChip(status: doc.approvalStatus),
                          if (doc.isRejected &&
                              doc.rejectionReason != null &&
                              doc.rejectionReason!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reason: ${doc.rejectionReason!}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please re-upload this document after correction.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_red_eye,
                            color: AppColors.primary,
                          ),
                          onPressed: () =>
                              _viewDocument(doc.fileId, doc.documentName),
                          tooltip: 'View Document',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.upload_file,
                            color: doc.isRejected
                                ? AppColors.warning
                                : AppColors.textTertiary,
                          ),
                          onPressed: uploadState.isLoading
                              ? null
                              : () => _pickAndUploadDocument(
                                    replaceTarget: doc,
                                  ),
                          tooltip: doc.isRejected
                              ? 'Re-upload Document'
                              : 'Replace Document',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Document'),
                                content: const Text(
                                  'Are you sure you want to delete this document?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ref
                                          .read(documentNotifierProvider.notifier)
                                          .deleteDocument(doc.id, doc.fileId);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          tooltip: 'Delete Document',
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(
                  begin: 20,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutQuart,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading documents: $e')),
      ),
    );
  }
}

class _ApprovalStatusChip extends StatelessWidget {
  final String status;

  const _ApprovalStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final label = switch (normalized) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => 'Pending Review',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
