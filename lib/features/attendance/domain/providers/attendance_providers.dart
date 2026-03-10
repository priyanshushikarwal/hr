import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Attendance State
class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;
  final int selectedMonth;
  final int selectedYear;

  const AttendanceState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    required this.selectedMonth,
    required this.selectedYear,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? error,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  int get presentCount => records.where((r) => r.isPresent).length;
  int get absentCount => records.where((r) => r.isAbsent).length;
  int get halfDayCount => records.where((r) => r.isHalfDay).length;
  int get leaveCount => records.where((r) => r.isOnLeave).length;
}

/// Attendance Notifier
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final Ref _ref;

  AttendanceNotifier(this._repository, this._ref)
    : super(
        AttendanceState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        ),
      ) {
    loadAttendance();
  }

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadAttendance({
    int? month,
    int? year,
    String? employeeId,
  }) async {
    final m = month ?? state.selectedMonth;
    final y = year ?? state.selectedYear;
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedMonth: m,
      selectedYear: y,
    );

    try {
      final records = await _repository.getAttendanceForMonth(
        month: m,
        year: y,
        employeeId: employeeId,
        isOnline: _isOnline,
      );
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAttendance(AttendanceRecord record) async {
    try {
      await _repository.markAttendance(record, isOnline: _isOnline);
      await loadAttendance();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateAttendance(String docId, Map<String, dynamic> data) async {
    try {
      await _repository.updateAttendance(docId, data, isOnline: _isOnline);
      await loadAttendance();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAttendance(String docId) async {
    try {
      await _repository.deleteAttendance(docId, isOnline: _isOnline);
      await loadAttendance();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void changeMonth(int month, int year) {
    loadAttendance(month: month, year: year);
  }
}

/// Attendance Provider
final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
      final repository = ref.watch(attendanceRepositoryProvider);
      return AttendanceNotifier(repository, ref);
    });
