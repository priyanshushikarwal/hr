import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../config/appwrite_config.dart';
import '../config/hive_config.dart';
import 'appwrite_service.dart';
import 'offline_queue_manager.dart';

/// SyncService: Orchestrates data sync between Appwrite (remote) and Hive (local)
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final Databases _databases = AppwriteService.instance.databases;
  final OfflineQueueManager _offlineQueue = OfflineQueueManager.instance;
  bool _isSyncing = false;

  /// Sync all collections from Appwrite → Hive
  /// Each collection syncs independently — missing collections are silently skipped
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // First replay any queued offline operations
      await _replayOfflineQueue();

      // Then pull latest from Appwrite (each one independent — don't fail all if one 404s)
      final collections = [
        [AppwriteConfig.employeesCollectionId, HiveBoxes.employees],
        [AppwriteConfig.attendanceCollectionId, HiveBoxes.attendance],
        [AppwriteConfig.leaveRequestsCollectionId, HiveBoxes.leaveRequests],
        [AppwriteConfig.notificationsCollectionId, HiveBoxes.notifications],
        [AppwriteConfig.salaryStructuresCollectionId, HiveBoxes.officeSalary],
        [AppwriteConfig.factorySalaryCollectionId, HiveBoxes.factorySalary],
        [AppwriteConfig.paymentsCollectionId, HiveBoxes.payments],
        [AppwriteConfig.offerLettersCollectionId, HiveBoxes.offerLetters],
      ];

      for (final c in collections) {
        try {
          await _syncCollection(c[0], c[1]);
        } catch (e) {
          // Silently skip — collection may not exist yet in Appwrite
          // This is expected during initial setup
        }
      }

      // Update last sync time
      HiveService.syncMetaBox.put('lastSync', DateTime.now().toIso8601String());
    } catch (e) {
      print('SyncService.syncAll error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single collection
  Future<void> _syncCollection(String collectionId, String boxName) async {
    try {
      final box = HiveService.getBox(boxName);
      final List<Map<String, dynamic>> allDocs = [];
      int offset = 0;
      const int limit = 100;

      // Paginate through all documents
      while (true) {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          queries: [Query.limit(limit), Query.offset(offset)],
        );

        for (final doc in response.documents) {
          allDocs.add({...doc.data, 'id': doc.$id});
        }

        if (response.documents.length < limit) break;
        offset += limit;
      }

      // Clear box and re-insert
      await box.clear();
      for (final doc in allDocs) {
        await box.put(doc['id'], doc);
      }
    } catch (e) {
      print('SyncService._syncCollection($collectionId) error: $e');
    }
  }

  /// Replay pending offline operations
  Future<void> _replayOfflineQueue() async {
    final pending = _offlineQueue.getPending();
    for (final op in pending) {
      try {
        switch (op.type) {
          case 'create':
            await _databases.createDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: op.collection,
              documentId: op.documentId ?? ID.unique(),
              data: op.data ?? {},
            );
            break;
          case 'update':
            if (op.documentId != null) {
              await _databases.updateDocument(
                databaseId: AppwriteConfig.databaseId,
                collectionId: op.collection,
                documentId: op.documentId!,
                data: op.data ?? {},
              );
            }
            break;
          case 'delete':
            if (op.documentId != null) {
              await _databases.deleteDocument(
                databaseId: AppwriteConfig.databaseId,
                collectionId: op.collection,
                documentId: op.documentId!,
              );
            }
            break;
        }
        await _offlineQueue.remove(op.id);
      } catch (e) {
        op.retryCount++;
        if (op.retryCount >= 3) {
          // Give up after 3 retries
          await _offlineQueue.remove(op.id);
          print('SyncService: Giving up on operation ${op.id} after 3 retries');
        } else {
          await _offlineQueue.enqueue(op);
        }
      }
    }
  }

  /// Create a document (handles offline)
  Future<Map<String, dynamic>> createDocument({
    required String collectionId,
    required String boxName,
    required Map<String, dynamic> data,
    String? documentId,
    required bool isOnline,
  }) async {
    final docId = documentId ?? const Uuid().v4();
    final docData = {...data, 'id': docId};

    if (isOnline) {
      try {
        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          documentId: docId,
          data: data..remove('id'),
        );
        final resultData = {...doc.data, 'id': doc.$id};
        // Save to Hive
        final box = HiveService.getBox(boxName);
        await box.put(doc.$id, resultData);
        return resultData;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create: ${e.message}');
      }
    } else {
      // Save locally and queue
      final box = HiveService.getBox(boxName);
      await box.put(docId, docData);
      await _offlineQueue.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: collectionId,
          type: 'create',
          documentId: docId,
          data: data..remove('id'),
          timestamp: DateTime.now(),
        ),
      );
      return docData;
    }
  }

  /// Update a document (handles offline)
  Future<Map<String, dynamic>> updateDocument({
    required String collectionId,
    required String boxName,
    required String documentId,
    required Map<String, dynamic> data,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          documentId: documentId,
          data: data,
        );
        final resultData = {...doc.data, 'id': doc.$id};
        final box = HiveService.getBox(boxName);
        await box.put(doc.$id, resultData);
        return resultData;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update: ${e.message}');
      }
    } else {
      // Update locally and queue
      final box = HiveService.getBox(boxName);
      final existing = box.get(documentId);
      if (existing != null) {
        final updated = {...Map<String, dynamic>.from(existing), ...data};
        await box.put(documentId, updated);
      }
      await _offlineQueue.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: collectionId,
          type: 'update',
          documentId: documentId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return data;
    }
  }

  /// Delete a document (handles offline)
  Future<void> deleteDocument({
    required String collectionId,
    required String boxName,
    required String documentId,
    required bool isOnline,
  }) async {
    // Always remove from Hive
    final box = HiveService.getBox(boxName);
    await box.delete(documentId);

    if (isOnline) {
      try {
        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to delete: ${e.message}');
      }
    } else {
      await _offlineQueue.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: collectionId,
          type: 'delete',
          documentId: documentId,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Read all documents from a collection (tries Appwrite, fallback to Hive)
  Future<List<Map<String, dynamic>>> listDocuments({
    required String collectionId,
    required String boxName,
    required bool isOnline,
    List<String>? queries,
  }) async {
    if (isOnline) {
      try {
        final List<Map<String, dynamic>> allDocs = [];
        int offset = 0;
        const int limit = 100;

        while (true) {
          // Build the queries list properly
          final queryList = <String>[
            ...?queries,
            Query.limit(limit),
            Query.offset(offset),
          ];

          final response = await _databases.listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: collectionId,
            queries: queryList,
          );

          for (final doc in response.documents) {
            final docData = {...doc.data, 'id': doc.$id};
            allDocs.add(docData);
          }

          if (response.documents.length < limit) break;
          offset += limit;
        }

        // Cache in Hive
        final box = HiveService.getBox(boxName);
        await box.clear();
        for (final doc in allDocs) {
          await box.put(doc['id'], doc);
        }

        return allDocs;
      } catch (e) {
        // Fallback to Hive
        return _readFromHive(boxName);
      }
    } else {
      return _readFromHive(boxName);
    }
  }

  List<Map<String, dynamic>> _readFromHive(String boxName) {
    final box = HiveService.getBox(boxName);
    return box.values.map((v) => Map<String, dynamic>.from(v)).toList();
  }
}
