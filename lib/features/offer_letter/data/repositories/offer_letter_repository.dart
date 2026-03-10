import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/offer_letter_model.dart';

/// Offer Letter Repository — Dual Data Layer
class OfferLetterRepository {
  final Databases _databases;

  OfferLetterRepository() : _databases = AppwriteService.instance.databases;

  static const _collectionId = AppwriteConfig.offerLettersCollectionId;
  static const _boxName = HiveBoxes.offerLetters;

  /// Get all offer letters
  Future<List<OfferLetter>> getOfferLetters({
    String? status,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final queries = <String>[
          Query.limit(100),
          Query.orderDesc('\$createdAt'),
        ];
        if (status != null) queries.add(Query.equal('status', status));

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );

        final letters = response.documents
            .map((doc) => OfferLetter.fromJson({...doc.data, 'id': doc.$id}))
            .toList();

        final box = HiveService.getBox(_boxName);
        for (final l in letters) {
          await box.put(l.id, l.toJson());
        }
        return letters;
      } catch (_) {
        return _getFromHive(status: status);
      }
    } else {
      return _getFromHive(status: status);
    }
  }

  List<OfferLetter> _getFromHive({String? status}) {
    final box = HiveService.getBox(_boxName);
    var letters = box.values
        .map((v) => OfferLetter.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    if (status != null)
      letters = letters.where((l) => l.status == status).toList();
    letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return letters;
  }

  /// Create offer letter
  Future<OfferLetter> createOfferLetter(
    OfferLetter letter, {
    required bool isOnline,
  }) async {
    final data = letter.toJson()..remove('id');

    if (isOnline) {
      try {
        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: ID.unique(),
          data: data,
        );
        final result = OfferLetter.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create offer letter: ${e.message}');
      }
    } else {
      final docId = const Uuid().v4();
      final local = letter.copyWith(id: docId);
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

  /// Update offer letter status (approval workflow)
  Future<OfferLetter> updateStatus(
    String documentId,
    String newStatus, {
    String? approvedBy,
    required bool isOnline,
  }) async {
    final data = <String, dynamic>{
      'status': newStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (newStatus == 'approved') {
      data['approvedBy'] = approvedBy;
      data['approvedAt'] = DateTime.now().toIso8601String();
    }
    if (newStatus == 'sent') {
      data['sentAt'] = DateTime.now().toIso8601String();
    }

    if (isOnline) {
      try {
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: documentId,
          data: data,
        );
        final result = OfferLetter.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update offer letter: ${e.message}');
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
      return OfferLetter.fromJson(
        Map<String, dynamic>.from(box.get(documentId)!),
      );
    }
  }
}
