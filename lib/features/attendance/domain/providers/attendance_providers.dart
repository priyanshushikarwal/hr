import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';

/// Attendance Repository Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Selected month for attendance view
final selectedAttendanceMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Selected employee for attendance view
final selectedAttendanceEmployeeProvider = StateProvider<String?>((ref) {
  return null;
});

/// Attendance records for the selected date
class AttendanceListState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;

  const AttendanceListState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });
}

/// Attendance by date provider
final attendanceByDateProvider =
    FutureProvider.family<List<AttendanceRecord>, DateTime>((ref, date) async {
      final repo = ref.watch(attendanceRepositoryProvider);
      return await repo.getAttendanceByDate(date);
    });

/// Monthly attendance provider
final monthlyAttendanceProvider =
    FutureProvider.family<
      List<AttendanceRecord>,
      ({String employeeId, int month, int year})
    >((ref, params) async {
      final repo = ref.watch(attendanceRepositoryProvider);
      return await repo.getMonthlyAttendance(
        employeeId: params.employeeId,
        month: params.month,
        year: params.year,
      );
    });

/// Attendance summary provider
final attendanceSummaryProvider =
    FutureProvider.family<
      AttendanceSummary,
      ({String employeeId, String employeeCode, int month, int year})
    >((ref, params) async {
      final repo = ref.watch(attendanceRepositoryProvider);
      return await repo.getAttendanceSummary(
        employeeId: params.employeeId,
        employeeCode: params.employeeCode,
        month: params.month,
        year: params.year,
      );
    });

/// Mark attendance action provider
final markAttendanceProvider =
    Provider<
      Future<AttendanceRecord> Function({
        required String employeeId,
        required String employeeCode,
        required DateTime date,
        required String status,
        String? remarks,
        String? markedBy,
      })
    >((ref) {
      final repo = ref.watch(attendanceRepositoryProvider);
      return ({
        required String employeeId,
        required String employeeCode,
        required DateTime date,
        required String status,
        String? remarks,
        String? markedBy,
      }) => repo.markAttendance(
        employeeId: employeeId,
        employeeCode: employeeCode,
        date: date,
        status: status,
        remarks: remarks,
        markedBy: markedBy,
      );
    });
