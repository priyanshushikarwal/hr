import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/repositories/leave_repository.dart';

/// Leave Repository Provider
final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository();
});

/// Leave List State
class LeaveListState {
  final List<LeaveRequest> requests;
  final bool isLoading;
  final String? error;
  final int pendingCount;

  const LeaveListState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.pendingCount = 0,
  });

  LeaveListState copyWith({
    List<LeaveRequest>? requests,
    bool? isLoading,
    String? error,
    int? pendingCount,
  }) {
    return LeaveListState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}

/// Leave List Notifier
class LeaveListNotifier extends StateNotifier<LeaveListState> {
  final LeaveRepository _repository;

  LeaveListNotifier(this._repository) : super(const LeaveListState()) {
    loadLeaveRequests();
  }

  Future<void> loadLeaveRequests({String? status, String? employeeId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final requests = await _repository.getLeaveRequests(
        status: status,
        employeeId: employeeId,
      );
      final pendingCount = await _repository.getPendingCount();
      state = LeaveListState(requests: requests, pendingCount: pendingCount);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approveLeave(String documentId, String approvedBy) async {
    try {
      await _repository.approveLeave(
        documentId: documentId,
        approvedBy: approvedBy,
      );
      await loadLeaveRequests();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectLeave(
    String documentId,
    String rejectedBy, {
    String? reason,
  }) async {
    try {
      await _repository.rejectLeave(
        documentId: documentId,
        rejectedBy: rejectedBy,
        reason: reason,
      );
      await loadLeaveRequests();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Leave List Provider
final leaveListProvider =
    StateNotifierProvider<LeaveListNotifier, LeaveListState>((ref) {
      final repository = ref.watch(leaveRepositoryProvider);
      return LeaveListNotifier(repository);
    });

/// Pending Leave Count Provider
final pendingLeaveCountProvider = Provider<int>((ref) {
  return ref.watch(leaveListProvider).pendingCount;
});

/// Leave Filter Provider
final leaveFilterProvider = StateProvider<String?>((ref) => null);
