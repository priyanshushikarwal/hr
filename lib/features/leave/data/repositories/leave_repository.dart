import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/leave_request_model.dart';

/// Leave Repository — Dual Data Layer (Appwrite + Hive)
class LeaveRepository {
  final Databases _databases;

  LeaveRepository() : _databases = AppwriteService.instance.databases;

  static const _collectionId = AppwriteConfig.leaveRequestsCollectionId;
  static const _boxName = HiveBoxes.leaveRequests;

  // ==== READ ====

  Future<List<LeaveRequest>> getLeaveRequests({
    String? status,
    String? employeeId,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final queries = <String>[
          Query.limit(100),
          Query.orderDesc('\$createdAt'),
        ];
        if (status != null && status.isNotEmpty)
          queries.add(Query.equal('status', status));
        if (employeeId != null)
          queries.add(Query.equal('employeeId', employeeId));

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );

        final requests = response.documents
            .map((doc) => LeaveRequest.fromJson({...doc.data, 'id': doc.$id}))
            .toList();

        final box = HiveService.getBox(_boxName);
        for (final r in requests) {
          await box.put(r.id, r.toJson());
        }
        return requests;
      } catch (_) {
        return _getFromHive(status: status, employeeId: employeeId);
      }
    } else {
      return _getFromHive(status: status, employeeId: employeeId);
    }
  }

  List<LeaveRequest> _getFromHive({String? status, String? employeeId}) {
    final box = HiveService.getBox(_boxName);
    var requests = box.values
        .map((v) => LeaveRequest.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    if (status != null && status.isNotEmpty) {
      requests = requests.where((r) => r.status == status).toList();
    }
    if (employeeId != null) {
      requests = requests.where((r) => r.employeeId == employeeId).toList();
    }
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  // ==== CREATE ====

  Future<LeaveRequest> createLeaveRequest(
    LeaveRequest request, {
    required bool isOnline,
  }) async {
    final data = request.toJson()..remove('id');

    if (isOnline) {
      try {
        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: ID.unique(),
          data: data,
        );
        final result = LeaveRequest.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create leave request: ${e.message}');
      }
    } else {
      final docId = const Uuid().v4();
      final local = request.copyWith(id: docId);
      final box = HiveService.getBox(_boxName);
      await box.put(docId, local.toJson());
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'create',
          documentId: docId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return local;
    }
  }

  // ==== APPROVE / REJECT ====

  Future<LeaveRequest> approveLeave(
    String documentId,
    String approvedBy, {
    required bool isOnline,
  }) async {
    // Check if already approved
    final existing = await _getById(documentId, isOnline: isOnline);
    if (existing != null && existing.status == 'approved') {
      throw Exception('Leave request already approved. Cannot approve twice.');
    }

    final data = <String, dynamic>{
      'status': 'approved',
      'approvedBy': approvedBy,
      'approvedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    return _updateDocument(documentId, data, isOnline: isOnline);
  }

  Future<LeaveRequest> rejectLeave(
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

  // ==== HELPERS ====

  Future<LeaveRequest?> _getById(
    String documentId, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final doc = await _databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: documentId,
        );
        return LeaveRequest.fromJson({...doc.data, 'id': doc.$id});
      } catch (_) {
        return _getByIdFromHive(documentId);
      }
    } else {
      return _getByIdFromHive(documentId);
    }
  }

  LeaveRequest? _getByIdFromHive(String documentId) {
    final box = HiveService.getBox(_boxName);
    final data = box.get(documentId);
    if (data != null)
      return LeaveRequest.fromJson(Map<String, dynamic>.from(data));
    return null;
  }

  Future<LeaveRequest> _updateDocument(
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
        final result = LeaveRequest.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update leave request: ${e.message}');
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
      return LeaveRequest.fromJson(
        Map<String, dynamic>.from(box.get(documentId)!),
      );
    }
  }
}
