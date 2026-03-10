import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/payment_model.dart';

/// Payments Repository — Dual Data Layer
class PaymentRepository {
  final Databases _databases;

  PaymentRepository() : _databases = AppwriteService.instance.databases;

  static const _collectionId = AppwriteConfig.paymentsCollectionId;
  static const _boxName = HiveBoxes.payments;

  /// Get payments for a month
  Future<List<PaymentRecord>> getPayments({
    required int month,
    required int year,
    String? status,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final queries = <String>[
          Query.equal('month', month),
          Query.equal('year', year),
          Query.limit(100),
        ];
        if (status != null) queries.add(Query.equal('status', status));

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );

        final records = response.documents
            .map((doc) => PaymentRecord.fromJson({...doc.data, 'id': doc.$id}))
            .toList();

        final box = HiveService.getBox(_boxName);
        for (final r in records) {
          await box.put(r.id, r.toJson());
        }
        return records;
      } catch (_) {
        return _getFromHive(month: month, year: year, status: status);
      }
    } else {
      return _getFromHive(month: month, year: year, status: status);
    }
  }

  List<PaymentRecord> _getFromHive({int? month, int? year, String? status}) {
    final box = HiveService.getBox(_boxName);
    var records = box.values
        .map((v) => PaymentRecord.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    if (month != null)
      records = records.where((r) => r.month == month).toList();
    if (year != null) records = records.where((r) => r.year == year).toList();
    if (status != null)
      records = records.where((r) => r.status == status).toList();
    return records;
  }

  /// Process salary — creates a locked payment record
  Future<PaymentRecord> processSalary(
    PaymentRecord record, {
    required bool isOnline,
  }) async {
    // Check if already processed — cannot process twice
    final existing = await _checkExisting(
      record.employeeId,
      record.month,
      record.year,
      isOnline: isOnline,
    );
    if (existing != null && existing.isLocked) {
      throw Exception(
        'Salary already processed for ${record.employeeName} for ${record.month}/${record.year}',
      );
    }

    final lockedRecord = record.copyWith(isLocked: true, status: 'processed');
    final data = lockedRecord.toJson()..remove('id');

    if (isOnline) {
      try {
        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: ID.unique(),
          data: data,
        );
        final result = PaymentRecord.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to process salary: ${e.message}');
      }
    } else {
      final docId = const Uuid().v4();
      final local = lockedRecord.copyWith(id: docId);
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

  /// Update payment (e.g., mark as paid with transaction number)
  Future<PaymentRecord> updatePayment(
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
        final result = PaymentRecord.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update payment: ${e.message}');
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
      return PaymentRecord.fromJson(
        Map<String, dynamic>.from(box.get(documentId)!),
      );
    }
  }

  Future<PaymentRecord?> _checkExisting(
    String employeeId,
    int month,
    int year, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: [
            Query.equal('employeeId', employeeId),
            Query.equal('month', month),
            Query.equal('year', year),
            Query.limit(1),
          ],
        );
        if (response.documents.isNotEmpty) {
          final doc = response.documents.first;
          return PaymentRecord.fromJson({...doc.data, 'id': doc.$id});
        }
        return null;
      } catch (_) {
        return null;
      }
    } else {
      final box = HiveService.getBox(_boxName);
      for (final v in box.values) {
        final map = Map<String, dynamic>.from(v);
        if (map['employeeId'] == employeeId &&
            map['month'] == month &&
            map['year'] == year) {
          return PaymentRecord.fromJson(map);
        }
      }
      return null;
    }
  }
}
