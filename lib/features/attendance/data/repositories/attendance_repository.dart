import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/attendance_models.dart';

/// Attendance Repository - CRUD via Appwrite
class AttendanceRepository {
  final Databases _databases;

  AttendanceRepository() : _databases = AppwriteService.instance.databases;

  /// Get attendance for a specific employee for a month
  Future<List<AttendanceRecord>> getMonthlyAttendance({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        queries: [
          Query.equal('employeeId', employeeId),
          Query.greaterThanEqual('date', startDate.toIso8601String()),
          Query.lessThanEqual('date', endDate.toIso8601String()),
          Query.orderAsc('date'),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => AttendanceRecord.fromJson({...doc.data, 'id': doc.$id}))
          .toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch attendance: ${e.message}');
    }
  }

  /// Get all attendance records for a given date
  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        queries: [
          Query.greaterThanEqual('date', startOfDay.toIso8601String()),
          Query.lessThanEqual('date', endOfDay.toIso8601String()),
          Query.limit(500),
        ],
      );

      return response.documents
          .map((doc) => AttendanceRecord.fromJson({...doc.data, 'id': doc.$id}))
          .toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch attendance: ${e.message}');
    }
  }

  /// Mark attendance for an employee (HR action)
  /// Also checks for duplicate entries
  Future<AttendanceRecord> markAttendance({
    required String employeeId,
    required String employeeCode,
    required DateTime date,
    required String status,
    String? remarks,
    String? markedBy,
    bool visitMode = false,
    String? selfieUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Check for existing attendance on this date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final existing = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        queries: [
          Query.equal('employeeId', employeeId),
          Query.greaterThanEqual('date', startOfDay.toIso8601String()),
          Query.lessThanEqual('date', endOfDay.toIso8601String()),
          Query.limit(1),
        ],
      );

      final now = DateTime.now();
      final data = {
        'employeeId': employeeId,
        'employeeCode': employeeCode,
        'date': startOfDay.toIso8601String(),
        'status': status,
        'remarks': remarks ?? '',
        'createdBy': markedBy ?? 'system',
        'visitMode': visitMode,
        'selfieUrl': selfieUrl,
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': now.toIso8601String(),
      };

      if (existing.documents.isNotEmpty) {
        // Update existing attendance
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.attendanceCollectionId,
          documentId: existing.documents.first.$id,
          data: data,
        );
        return AttendanceRecord.fromJson({...doc.data, 'id': doc.$id});
      } else {
        // Create new attendance record
        data['createdAt'] = now.toIso8601String();
        data['checkIn'] = status == 'present' ? now.toIso8601String() : null;

        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.attendanceCollectionId,
          documentId: ID.unique(),
          data: data,
        );
        return AttendanceRecord.fromJson({...doc.data, 'id': doc.$id});
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to mark attendance: ${e.message}');
    }
  }

  /// Update check-in / check-out times
  Future<AttendanceRecord> updateCheckTimes({
    required String documentId,
    DateTime? checkIn,
    DateTime? checkOut,
    double? hoursWorked,
    double? overtimeHours,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (checkIn != null) data['checkIn'] = checkIn.toIso8601String();
      if (checkOut != null) data['checkOut'] = checkOut.toIso8601String();
      if (hoursWorked != null) data['hoursWorked'] = hoursWorked;
      if (overtimeHours != null) data['overtimeHours'] = overtimeHours;

      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        documentId: documentId,
        data: data,
      );
      return AttendanceRecord.fromJson({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      throw Exception('Failed to update attendance: ${e.message}');
    }
  }

  /// Get attendance summary for a month
  Future<AttendanceSummary> getAttendanceSummary({
    required String employeeId,
    required String employeeCode,
    required int month,
    required int year,
  }) async {
    final records = await getMonthlyAttendance(
      employeeId: employeeId,
      month: month,
      year: year,
    );

    int presentDays = 0;
    int absentDays = 0;
    int halfDays = 0;
    int leaveDays = 0;
    int holidays = 0;
    int weekends = 0;
    double totalHours = 0;
    double totalOT = 0;

    for (final record in records) {
      switch (record.status) {
        case 'present':
          presentDays++;
          break;
        case 'absent':
          absentDays++;
          break;
        case 'half_day':
          halfDays++;
          break;
        case 'leave':
          leaveDays++;
          break;
        case 'holiday':
          holidays++;
          break;
        case 'weekend':
          weekends++;
          break;
      }
      totalHours += record.hoursWorked;
      totalOT += record.overtimeHours;
    }

    final totalDays = DateTime(year, month + 1, 0).day;

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
      totalOvertimeHours: totalOT,
    );
  }
}
