import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/repositories/leave_repository.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository();
});

class LeaveListState {
  final List<LeaveRequest> requests;
  final bool isLoading;
  final String? error;

  const LeaveListState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  LeaveListState copyWith({
    List<LeaveRequest>? requests,
    bool? isLoading,
    String? error,
  }) {
    return LeaveListState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get pendingCount => requests.where((r) => r.status == 'pending').length;
  int get approvedCount => requests.where((r) => r.status == 'approved').length;
  int get rejectedCount => requests.where((r) => r.status == 'rejected').length;
}

class LeaveListNotifier extends StateNotifier<LeaveListState> {
  final LeaveRepository _repository;
  final Ref _ref;

  LeaveListNotifier(this._repository, this._ref)
    : super(const LeaveListState()) {
    loadRequests();
  }

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadRequests({String? status, String? employeeId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final requests = await _repository.getLeaveRequests(
        status: status,
        employeeId: employeeId,
        isOnline: _isOnline,
      );
      state = LeaveListState(requests: requests);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createRequest(LeaveRequest request) async {
    try {
      await _repository.createLeaveRequest(request, isOnline: _isOnline);
      await loadRequests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> approve(String docId, String approvedBy) async {
    try {
      await _repository.approveLeave(docId, approvedBy, isOnline: _isOnline);
      await loadRequests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> reject(String docId, String rejectedBy, {String? reason}) async {
    try {
      await _repository.rejectLeave(
        docId,
        rejectedBy,
        reason: reason,
        isOnline: _isOnline,
      );
      await loadRequests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final leaveListProvider =
    StateNotifierProvider<LeaveListNotifier, LeaveListState>((ref) {
      final repo = ref.watch(leaveRepositoryProvider);
      return LeaveListNotifier(repo, ref);
    });
