import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/salary_models.dart';

/// Salary Repository — Dual Data Layer for Office & Factory Salary
class SalaryRepository {
  final Databases _databases;

  SalaryRepository() : _databases = AppwriteService.instance.databases;

  // ==== OFFICE SALARY ====

  static const _officeCollectionId =
      AppwriteConfig.salaryStructuresCollectionId;
  static const _officeBoxName = HiveBoxes.officeSalary;

  /// Get salary structure for an employee
  Future<OfficeSalaryStructure?> getOfficeSalary(
    String employeeId, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _officeCollectionId,
          queries: [
            Query.equal('employeeId', employeeId),
            Query.orderDesc('\$createdAt'),
            Query.limit(1),
          ],
        );
        if (response.documents.isEmpty) return null;
        final doc = response.documents.first;
        final result = OfficeSalaryStructure.fromJson({
          ...doc.data,
          'id': doc.$id,
        });
        // Cache
        final box = HiveService.getBox(_officeBoxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException {
        return _getOfficeSalaryFromHive(employeeId);
      }
    } else {
      return _getOfficeSalaryFromHive(employeeId);
    }
  }

  OfficeSalaryStructure? _getOfficeSalaryFromHive(String employeeId) {
    final box = HiveService.getBox(_officeBoxName);
    for (final v in box.values) {
      final map = Map<String, dynamic>.from(v);
      if (map['employeeId'] == employeeId) {
        return OfficeSalaryStructure.fromJson(map);
      }
    }
    return null;
  }

  /// Get all salary structures
  Future<List<OfficeSalaryStructure>> getAllOfficeSalaries({
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _officeCollectionId,
          queries: [Query.limit(100)],
        );
        final results = response.documents
            .map(
              (doc) =>
                  OfficeSalaryStructure.fromJson({...doc.data, 'id': doc.$id}),
            )
            .toList();
        // Cache
        final box = HiveService.getBox(_officeBoxName);
        for (final s in results) {
          await box.put(s.id, s.toJson());
        }
        return results;
      } catch (_) {
        return _getAllFromHive(_officeBoxName, OfficeSalaryStructure.fromJson);
      }
    } else {
      return _getAllFromHive(_officeBoxName, OfficeSalaryStructure.fromJson);
    }
  }

  /// Save/Update office salary structure
  Future<OfficeSalaryStructure> saveOfficeSalary(
    OfficeSalaryStructure salary, {
    required bool isOnline,
  }) async {
    final data = salary.toJson()..remove('id');

    if (salary.id.isNotEmpty && salary.id != '') {
      // Update existing
      if (isOnline) {
        try {
          final doc = await _databases.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: _officeCollectionId,
            documentId: salary.id,
            data: data,
          );
          final result = OfficeSalaryStructure.fromJson({
            ...doc.data,
            'id': doc.$id,
          });
          final box = HiveService.getBox(_officeBoxName);
          await box.put(result.id, result.toJson());
          return result;
        } on AppwriteException catch (e) {
          throw Exception('Failed to update salary: ${e.message}');
        }
      } else {
        final box = HiveService.getBox(_officeBoxName);
        await box.put(salary.id, salary.toJson());
        await OfflineQueueManager.instance.enqueue(
          OfflineOperation(
            id: const Uuid().v4(),
            collection: _officeCollectionId,
            type: 'update',
            documentId: salary.id,
            data: data,
            timestamp: DateTime.now(),
          ),
        );
        return salary;
      }
    } else {
      // Create new
      if (isOnline) {
        try {
          final doc = await _databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: _officeCollectionId,
            documentId: ID.unique(),
            data: data,
          );
          final result = OfficeSalaryStructure.fromJson({
            ...doc.data,
            'id': doc.$id,
          });
          final box = HiveService.getBox(_officeBoxName);
          await box.put(result.id, result.toJson());
          return result;
        } on AppwriteException catch (e) {
          throw Exception('Failed to create salary: ${e.message}');
        }
      } else {
        final docId = const Uuid().v4();
        final localSalary = salary.copyWith(id: docId);
        final box = HiveService.getBox(_officeBoxName);
        await box.put(docId, localSalary.toJson());
        await OfflineQueueManager.instance.enqueue(
          OfflineOperation(
            id: const Uuid().v4(),
            collection: _officeCollectionId,
            type: 'create',
            documentId: docId,
            data: data,
            timestamp: DateTime.now(),
          ),
        );
        return localSalary;
      }
    }
  }

  // ==== FACTORY SALARY ====

  static const _factoryCollectionId = AppwriteConfig.factorySalaryCollectionId;
  static const _factoryBoxName = HiveBoxes.factorySalary;

  /// Get factory salary entries for a month
  Future<List<FactorySalaryEntry>> getFactorySalaryEntries({
    required int month,
    required int year,
    String? employeeId,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

        final queries = <String>[
          Query.greaterThanEqual('date', startDate.toIso8601String()),
          Query.lessThanEqual('date', endDate.toIso8601String()),
          Query.limit(500),
          Query.orderDesc('date'),
        ];
        if (employeeId != null)
          queries.add(Query.equal('employeeId', employeeId));

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _factoryCollectionId,
          queries: queries,
        );

        final entries = response.documents
            .map(
              (doc) =>
                  FactorySalaryEntry.fromJson({...doc.data, 'id': doc.$id}),
            )
            .toList();

        // Cache
        final box = HiveService.getBox(_factoryBoxName);
        for (final e in entries) {
          await box.put(e.id, e.toJson());
        }
        return entries;
      } catch (e) {
        return _getFactoryFromHive(
          month: month,
          year: year,
          employeeId: employeeId,
        );
      }
    } else {
      return _getFactoryFromHive(
        month: month,
        year: year,
        employeeId: employeeId,
      );
    }
  }

  List<FactorySalaryEntry> _getFactoryFromHive({
    int? month,
    int? year,
    String? employeeId,
  }) {
    final box = HiveService.getBox(_factoryBoxName);
    var entries = box.values
        .map((v) => FactorySalaryEntry.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    if (month != null && year != null) {
      entries = entries
          .where((e) => e.date.month == month && e.date.year == year)
          .toList();
    }
    if (employeeId != null) {
      entries = entries.where((e) => e.employeeId == employeeId).toList();
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Create factory salary entry
  Future<FactorySalaryEntry> createFactoryEntry(
    FactorySalaryEntry entry, {
    required bool isOnline,
  }) async {
    final data = entry.toJson()..remove('id');

    if (isOnline) {
      try {
        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _factoryCollectionId,
          documentId: ID.unique(),
          data: data,
        );
        final result = FactorySalaryEntry.fromJson({
          ...doc.data,
          'id': doc.$id,
        });
        final box = HiveService.getBox(_factoryBoxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create factory entry: ${e.message}');
      }
    } else {
      final docId = const Uuid().v4();
      final local = entry.copyWith(id: docId);
      final box = HiveService.getBox(_factoryBoxName);
      await box.put(docId, local.toJson());
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _factoryCollectionId,
          type: 'create',
          documentId: docId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return local;
    }
  }

  /// Update factory salary entry
  Future<FactorySalaryEntry> updateFactoryEntry(
    String documentId,
    Map<String, dynamic> data, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _factoryCollectionId,
          documentId: documentId,
          data: data,
        );
        final result = FactorySalaryEntry.fromJson({
          ...doc.data,
          'id': doc.$id,
        });
        final box = HiveService.getBox(_factoryBoxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update factory entry: ${e.message}');
      }
    } else {
      final box = HiveService.getBox(_factoryBoxName);
      final existing = box.get(documentId);
      if (existing != null) {
        final updated = {...Map<String, dynamic>.from(existing), ...data};
        await box.put(documentId, updated);
      }
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _factoryCollectionId,
          type: 'update',
          documentId: documentId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return FactorySalaryEntry.fromJson(
        Map<String, dynamic>.from(box.get(documentId)!),
      );
    }
  }

  /// Delete factory salary entry
  Future<void> deleteFactoryEntry(
    String documentId, {
    required bool isOnline,
  }) async {
    final box = HiveService.getBox(_factoryBoxName);
    await box.delete(documentId);
    if (isOnline) {
      try {
        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _factoryCollectionId,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to delete factory entry: ${e.message}');
      }
    } else {
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _factoryCollectionId,
          type: 'delete',
          documentId: documentId,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // ==== ADVANCE SALARY ====

  static const _advanceCollectionId = AppwriteConfig.advanceSalaryCollectionId;
  static const _advanceBoxName = HiveBoxes.advanceSalary;

  /// Get all advances for an employee
  Future<List<AdvanceSalary>> getEmployeeAdvances(
    String employeeId, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _advanceCollectionId,
          queries: [
            Query.equal('employeeId', employeeId),
            Query.orderDesc('requestDate'),
            Query.limit(100),
          ],
        );
        final advances = response.documents
            .map(
              (doc) => AdvanceSalary.fromJson({
                ...doc.data,
                'id': doc.$id,
              }),
            )
            .toList();
        // Cache
        final box = HiveService.getBox(_advanceBoxName);
        for (final adv in advances) {
          await box.put(adv.id, adv.toJson());
        }
        return advances;
      } catch (_) {
        return _getAdvancesFromHive(employeeId);
      }
    } else {
      return _getAdvancesFromHive(employeeId);
    }
  }

  List<AdvanceSalary> _getAdvancesFromHive(String employeeId) {
    final box = HiveService.getBox(_advanceBoxName);
    final advances = <AdvanceSalary>[];
    for (final v in box.values) {
      final map = Map<String, dynamic>.from(v);
      if (map['employeeId'] == employeeId) {
        advances.add(AdvanceSalary.fromJson(map));
      }
    }
    advances.sort((a, b) => b.requestDate.compareTo(a.requestDate));
    return advances;
  }

  /// Get all pending advances
  Future<List<AdvanceSalary>> getPendingAdvances({
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _advanceCollectionId,
          queries: [
            Query.equal('status', 'approved'),
            Query.orderDesc('requestDate'),
            Query.limit(100),
          ],
        );
        final advances = response.documents
            .map(
              (doc) => AdvanceSalary.fromJson({
                ...doc.data,
                'id': doc.$id,
              }),
            )
            .toList();
        // Cache
        final box = HiveService.getBox(_advanceBoxName);
        for (final adv in advances) {
          await box.put(adv.id, adv.toJson());
        }
        return advances;
      } catch (_) {
        return _getPendingAdvancesFromHive();
      }
    } else {
      return _getPendingAdvancesFromHive();
    }
  }

  List<AdvanceSalary> _getPendingAdvancesFromHive() {
    final box = HiveService.getBox(_advanceBoxName);
    return box.values
        .map((v) => AdvanceSalary.fromJson(Map<String, dynamic>.from(v)))
        .where((adv) => adv.status == 'approved')
        .toList();
  }

  /// Create new advance salary request
  Future<AdvanceSalary> createAdvance(
    AdvanceSalary advance, {
    required bool isOnline,
  }) async {
    final data = advance.toJson()..remove('id');

    if (isOnline) {
      try {
        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _advanceCollectionId,
          documentId: ID.unique(),
          data: data,
        );
        final result = AdvanceSalary.fromJson({
          ...doc.data,
          'id': doc.$id,
        });
        final box = HiveService.getBox(_advanceBoxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create advance: ${e.message}');
      }
    } else {
      final docId = const Uuid().v4();
      final local = advance.copyWith(id: docId);
      final box = HiveService.getBox(_advanceBoxName);
      await box.put(docId, local.toJson());
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _advanceCollectionId,
          type: 'create',
          documentId: docId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return local;
    }
  }

  /// Update advance salary (approval, repayment tracking, etc.)
  Future<AdvanceSalary> updateAdvance(
    String documentId,
    AdvanceSalary advance, {
    required bool isOnline,
  }) async {
    final data = advance.toJson()..remove('id');

    if (isOnline) {
      try {
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _advanceCollectionId,
          documentId: documentId,
          data: data,
        );
        final result = AdvanceSalary.fromJson({
          ...doc.data,
          'id': doc.$id,
        });
        final box = HiveService.getBox(_advanceBoxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update advance: ${e.message}');
      }
    } else {
      final box = HiveService.getBox(_advanceBoxName);
      await box.put(documentId, advance.toJson());
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _advanceCollectionId,
          type: 'update',
          documentId: documentId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return advance;
    }
  }

  /// Get active pending advances for an employee (for salary deduction)
  Future<double> getTotalPendingAdvanceAmount(
    String employeeId, {
    required bool isOnline,
  }) async {
    final advances = await getEmployeeAdvances(
      employeeId,
      isOnline: isOnline,
    );
    
    // Sum all pending amounts from approved advances not yet cleared
    double totalPending = 0;
    for (final adv in advances) {
      if (adv.status == 'approved' || adv.status == 'partial') {
        totalPending += adv.pendingAmount;
      }
    }
    return totalPending;
  }

  /// Record advance repayment/deduction from salary
  Future<AdvanceSalary> recordAdvanceDeduction(
    String advanceId,
    double deductionAmount, {
    required bool isOnline,
  }) async {
    final box = HiveService.getBox(_advanceBoxName);
    final existing = box.get(advanceId);
    if (existing == null) {
      throw Exception('Advance not found');
    }

    final advanceMap = Map<String, dynamic>.from(existing);
    final advance = AdvanceSalary.fromJson(advanceMap);
    
    // Update repayment tracking
    final newRepaid = advance.repaidAmount + deductionAmount;
    final newPending = AdvanceSalary.calculatePendingAmount(
      advance.advanceAmount,
      newRepaid,
    );
    final newStatus = newPending <= 0 ? 'cleared' : 'partial';
    final clearanceDate = newPending <= 0 ? DateTime.now() : null;

    final updated = advance.copyWith(
      repaidAmount: newRepaid,
      pendingAmount: newPending,
      status: newStatus,
      clearanceDate: clearanceDate,
      installmentsCleared: advance.installmentsCleared + 1,
      updatedAt: DateTime.now(),
    );

    return updateAdvance(advanceId, updated, isOnline: isOnline);
  }

  // ==== Helper ====
  List<T> _getAllFromHive<T>(
    String boxName,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final box = HiveService.getBox(boxName);
    return box.values
        .map((v) => fromJson(Map<String, dynamic>.from(v)))
        .toList();
  }
}
