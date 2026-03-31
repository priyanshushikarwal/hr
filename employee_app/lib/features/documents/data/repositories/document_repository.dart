import 'dart:io';
import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/employee_document_model.dart';

class DocumentRepository {
  final Databases _databases;
  final Storage _storage;

  DocumentRepository()
    : _databases = AppwriteService.instance.databases,
      _storage = AppwriteService.instance.storage;

  Future<List<EmployeeDocument>> getEmployeeDocuments(String employeeId) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.employeeDocumentsCollectionId,
      queries: [
        Query.equal('employeeId', employeeId),
        Query.orderDesc('uploadedAt'),
      ],
    );

    return response.documents
        .map((doc) => EmployeeDocument.fromJson({...doc.data, 'id': doc.$id}))
        .toList();
  }

  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required String filePath,
    required String fileName,
    required String documentType,
  }) async {
    // 1. Upload to storage
    final file = await _storage.createFile(
      bucketId: AppwriteConfig.employeeDocumentsBucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(path: filePath, filename: fileName),
    );

    // 2. Get File URL
    final fileUrl =
        '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.employeeDocumentsBucketId}/files/${file.$id}/view?project=${AppwriteConfig.projectId}';

    // 3. Save to database
    final documentData = {
      'employeeId': employeeId,
      'documentName': fileName,
      'documentType': documentType,
      'fileId': file.$id,
      'fileUrl': fileUrl,
      'uploadedAt': DateTime.now().toIso8601String(),
      'approvalStatus': 'pending',
      'approvedBy': '',
      'reviewedAt': '',
      'rejectionReason': '',
    };

    final doc = await _databases.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.employeeDocumentsCollectionId,
      documentId: ID.unique(),
      data: documentData,
    );

    return EmployeeDocument.fromJson({...doc.data, '\$id': doc.$id});
  }

  Future<EmployeeDocument> replaceDocument({
    required String documentId,
    required String previousFileId,
    required String employeeId,
    required String filePath,
    required String fileName,
    required String documentType,
  }) async {
    final file = await _storage.createFile(
      bucketId: AppwriteConfig.employeeDocumentsBucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(path: filePath, filename: fileName),
    );

    final fileUrl =
        '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.employeeDocumentsBucketId}/files/${file.$id}/view?project=${AppwriteConfig.projectId}';

    final doc = await _databases.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.employeeDocumentsCollectionId,
      documentId: documentId,
      data: {
        'employeeId': employeeId,
        'documentName': fileName,
        'documentType': documentType,
        'fileId': file.$id,
        'fileUrl': fileUrl,
        'uploadedAt': DateTime.now().toIso8601String(),
        'approvalStatus': 'pending',
        'approvedBy': '',
        'reviewedAt': '',
        'rejectionReason': '',
      },
    );

    try {
      await _storage.deleteFile(
        bucketId: AppwriteConfig.employeeDocumentsBucketId,
        fileId: previousFileId,
      );
    } catch (_) {
      // Ignore storage cleanup failures after successful replacement.
    }

    return EmployeeDocument.fromJson({...doc.data, '\$id': doc.$id});
  }

  Future<void> deleteDocument(String documentId, String fileId) async {
    // 1. Delete from database
    await _databases.deleteDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.employeeDocumentsCollectionId,
      documentId: documentId,
    );

    // 2. Delete from storage
    try {
      await _storage.deleteFile(
        bucketId: AppwriteConfig.employeeDocumentsBucketId,
        fileId: fileId,
      );
    } catch (e) {
      // Ignored if storage cleanup fails
    }
  }
}
