import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/visit_model.dart';

/// Visit Repository — Dual Data Layer (Appwrite + Hive)
class VisitRepository {
  final Databases _databases;
  final Storage _storage;

  VisitRepository()
      : _databases = AppwriteService.instance.databases,
        _storage = AppwriteService.instance.storage;

  static const _collectionId = AppwriteConfig.visitsCollectionId;
  static const _boxName = HiveBoxes.visits;
  static const _bucketId = AppwriteConfig.visitSelfiesBucketId;

  // ==== READ ====

  /// Get all visit records (optionally filtered)
  Future<List<VisitRecord>> getVisits({
    String? status,
    String? employeeId,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final queries = <String>[
          Query.limit(100),
          Query.orderDesc('visitDate'),
        ];
        if (status != null && status.isNotEmpty) {
          queries.add(Query.equal('status', status));
        }
        if (employeeId != null) {
          queries.add(Query.equal('employeeId', employeeId));
        }

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );

        final records = response.documents
            .map(
              (doc) => VisitRecord.fromJson({...doc.data, 'id': doc.$id}),
            )
            .toList();

        // Cache to Hive
        final box = HiveService.getBox(_boxName);
        for (final r in records) {
          await box.put(r.id, r.toJson());
        }

        return records;
      } on AppwriteException catch (e) {
        print('VisitRepository error: ${e.message}');
        return _getFromHive(status: status, employeeId: employeeId);
      }
    } else {
      return _getFromHive(status: status, employeeId: employeeId);
    }
  }

  List<VisitRecord> _getFromHive({String? status, String? employeeId}) {
    final box = HiveService.getBox(_boxName);
    var records = box.values
        .map((v) => VisitRecord.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    if (status != null && status.isNotEmpty) {
      records = records.where((r) => r.status.value == status).toList();
    }
    if (employeeId != null) {
      records = records.where((r) => r.employeeId == employeeId).toList();
    }

    records.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    return records;
  }

  // ==== APPROVE / REJECT ====

  Future<VisitRecord> approveVisit(
    String documentId,
    String approvedBy, {
    required bool isOnline,
  }) async {
    final data = <String, dynamic>{
      'status': 'approved',
      'approvedBy': approvedBy,
      'approvedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    return _updateDocument(documentId, data, isOnline: isOnline);
  }

  Future<VisitRecord> rejectVisit(
    String documentId,
    String rejectedBy, {
    String? reason,
    required bool isOnline,
  }) async {
    final data = <String, dynamic>{
      'status': 'rejected',
      'approvedBy': rejectedBy,
      'approvedAt': DateTime.now().toIso8601String(),
      'rejectionReason': reason ?? '',
      'updatedAt': DateTime.now().toIso8601String(),
    };

    return _updateDocument(documentId, data, isOnline: isOnline);
  }

  // ==== SELFIE ====

  /// Download selfie bytes using authenticated Appwrite SDK
  Future<Uint8List> getSelfieBytes(String fileId) async {
    return await _storage.getFileView(
      bucketId: _bucketId,
      fileId: fileId,
    );
  }

  /// Download selfie preview (thumbnail) bytes
  Future<Uint8List> getSelfiePreviewBytes(String fileId, {int width = 300, int height = 300}) async {
    return await _storage.getFilePreview(
      bucketId: _bucketId,
      fileId: fileId,
      width: width,
      height: height,
    );
  }

  // ==== HELPERS ====

  Future<VisitRecord> _updateDocument(
    String documentId,
    Map<String, dynamic> data, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: documentId,
          data: data,
        );
        final result = VisitRecord.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update visit: ${e.message}');
      }
    } else {
      final box = HiveService.getBox(_boxName);
      final existing = box.get(documentId);
      if (existing != null) {
        final updated = {...Map<String, dynamic>.from(existing), ...data};
        await box.put(documentId, updated);
      }
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'update',
          documentId: documentId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return VisitRecord.fromJson(
        Map<String, dynamic>.from(box.get(documentId)!),
      );
    }
  }
}
