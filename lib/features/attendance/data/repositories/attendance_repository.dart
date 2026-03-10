import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/attendance_models.dart';

/// Attendance Repository — Dual Data Layer (Appwrite + Hive)
class AttendanceRepository {
  final Databases _databases;

  AttendanceRepository() : _databases = AppwriteService.instance.databases;

  static const _collectionId = AppwriteConfig.attendanceCollectionId;
  static const _boxName = HiveBoxes.attendance;

  // ==== READ ====

  /// Get attendance records for a month
  Future<List<AttendanceRecord>> getAttendanceForMonth({
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
          Query.limit(100),
          Query.orderDesc('date'),
        ];
        if (employeeId != null)
          queries.add(Query.equal('employeeId', employeeId));

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );

        final records = response.documents
            .map(
              (doc) => AttendanceRecord.fromJson({...doc.data, 'id': doc.$id}),
            )
            .toList();

        // Cache to Hive
        final box = HiveService.getBox(_boxName);
        for (final r in records) {
          await box.put(r.id, r.toJson());
        }

        return records;
      } on AppwriteException catch (e) {
        print('AttendanceRepository error: ${e.message}');
        return _getFromHive(month: month, year: year, employeeId: employeeId);
      }
    } else {
      return _getFromHive(month: month, year: year, employeeId: employeeId);
    }
  }

  List<AttendanceRecord> _getFromHive({
    int? month,
    int? year,
    String? employeeId,
  }) {
    final box = HiveService.getBox(_boxName);
    var records = box.values
        .map((v) => AttendanceRecord.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    if (month != null && year != null) {
      records = records
          .where((r) => r.date.month == month && r.date.year == year)
          .toList();
    }
    if (employeeId != null) {
      records = records.where((r) => r.employeeId == employeeId).toList();
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  // ==== CREATE ====

  /// Mark attendance — enforces one record per employee per date
  Future<AttendanceRecord> markAttendance(
    AttendanceRecord record, {
    required bool isOnline,
  }) async {
    // Check for duplicate
    final existing = await _checkDuplicate(
      record.employeeId,
      record.date,
      isOnline: isOnline,
    );
    if (existing != null) {
      throw Exception(
        'Attendance already marked for ${record.employeeCode} on ${record.date.toIso8601String().split('T')[0]}',
      );
    }

    final data = record.toJson()..remove('id');

    if (isOnline) {
      try {
        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: ID.unique(),
          data: data,
        );
        final result = AttendanceRecord.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to mark attendance: ${e.message}');
      }
    } else {
      final docId = const Uuid().v4();
      final localRecord = record.copyWith(id: docId);
      final box = HiveService.getBox(_boxName);
      await box.put(docId, localRecord.toJson());

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

      return localRecord;
    }
  }

  /// Check if attendance already exists for employee on date
  Future<AttendanceRecord?> _checkDuplicate(
    String employeeId,
    DateTime date, {
    required bool isOnline,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    if (isOnline) {
      try {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: [
            Query.equal('employeeId', employeeId),
            Query.greaterThanEqual('date', startOfDay.toIso8601String()),
            Query.lessThanEqual('date', endOfDay.toIso8601String()),
            Query.limit(1),
          ],
        );
        if (response.documents.isNotEmpty) {
          final doc = response.documents.first;
          return AttendanceRecord.fromJson({...doc.data, 'id': doc.$id});
        }
        return null;
      } catch (_) {
        return _checkDuplicateInHive(employeeId, dateStr);
      }
    } else {
      return _checkDuplicateInHive(employeeId, dateStr);
    }
  }

  AttendanceRecord? _checkDuplicateInHive(String employeeId, String dateStr) {
    final box = HiveService.getBox(_boxName);
    for (final v in box.values) {
      final map = Map<String, dynamic>.from(v);
      if (map['employeeId'] == employeeId) {
        final d = (map['date'] as String?)?.split('T')[0];
        if (d == dateStr) return AttendanceRecord.fromJson(map);
      }
    }
    return null;
  }

  // ==== UPDATE ====

  Future<AttendanceRecord> updateAttendance(
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
        final result = AttendanceRecord.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update attendance: ${e.message}');
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
      return AttendanceRecord.fromJson(
        Map<String, dynamic>.from(box.get(documentId)!),
      );
    }
  }

  // ==== DELETE ====

  Future<void> deleteAttendance(
    String documentId, {
    required bool isOnline,
  }) async {
    final box = HiveService.getBox(_boxName);
    await box.delete(documentId);

    if (isOnline) {
      try {
        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to delete attendance: ${e.message}');
      }
    } else {
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'delete',
          documentId: documentId,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // ==== SUMMARY ====

  /// Get attendance summary for a month
  AttendanceSummary getMonthSummary(
    List<AttendanceRecord> records,
    String employeeId,
    String employeeCode,
    int month,
    int year,
  ) {
    final empRecords = records
        .where((r) => r.employeeId == employeeId)
        .toList();
    final totalDays = DateTime(year, month + 1, 0).day;
    final presentDays = empRecords.where((r) => r.isPresent).length;
    final absentDays = empRecords.where((r) => r.isAbsent).length;
    final halfDays = empRecords.where((r) => r.isHalfDay).length;
    final leaveDays = empRecords.where((r) => r.isOnLeave).length;
    final holidays = empRecords.where((r) => r.isHoliday).length;
    final weekends = empRecords.where((r) => r.isWeekend).length;
    final totalHours = empRecords.fold<double>(
      0,
      (sum, r) => sum + r.hoursWorked,
    );
    final totalOt = empRecords.fold<double>(
      0,
      (sum, r) => sum + r.overtimeHours,
    );

    return AttendanceSummary(
      employeeId: employeeId,
      employeeCode: employeeCode,
      month: month,
      year: year,
      totalDays: totalDays,
      presentDays: presentDays,
      absentDays: absentDays,
      halfDays: halfDays,
      leaveDays: leaveDays,
      holidays: holidays,
      weekends: weekends,
      totalHoursWorked: totalHours,
      totalOvertimeHours: totalOt,
    );
  }
}
