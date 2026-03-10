import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/visit_repository.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});

/// Visit List State
class VisitListState {
  final List<VisitRecord> visits;
  final bool isLoading;
  final String? error;

  const VisitListState({
    this.visits = const [],
    this.isLoading = false,
    this.error,
  });

  VisitListState copyWith({
    List<VisitRecord>? visits,
    bool? isLoading,
    String? error,
  }) {
    return VisitListState(
      visits: visits ?? this.visits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get pendingCount =>
      visits.where((v) => v.status == VisitStatus.pending).length;
  int get approvedCount =>
      visits.where((v) => v.status == VisitStatus.approved).length;
  int get rejectedCount =>
      visits.where((v) => v.status == VisitStatus.rejected).length;
}

/// Visit List Notifier
class VisitListNotifier extends StateNotifier<VisitListState> {
  final VisitRepository _repository;
  final Ref _ref;

  VisitListNotifier(this._repository, this._ref)
      : super(const VisitListState()) {
    loadVisits();
  }

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadVisits({String? status, String? employeeId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final visits = await _repository.getVisits(
        status: status,
        employeeId: employeeId,
        isOnline: _isOnline,
      );
      state = state.copyWith(visits: visits, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> approve(String visitId, String approvedBy) async {
    try {
      await _repository.approveVisit(visitId, approvedBy, isOnline: _isOnline);
      await loadVisits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> reject(String visitId, String rejectedBy,
      {String? reason}) async {
    try {
      await _repository.rejectVisit(visitId, rejectedBy,
          reason: reason, isOnline: _isOnline);
      await loadVisits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<Uint8List> getSelfieBytes(String fileId) {
    return _repository.getSelfieBytes(fileId);
  }

  Future<Uint8List> getSelfiePreviewBytes(String fileId) {
    return _repository.getSelfiePreviewBytes(fileId);
  }
}

/// Visit List Provider
final visitListProvider =
    StateNotifierProvider<VisitListNotifier, VisitListState>((ref) {
  final repository = ref.watch(visitRepositoryProvider);
  return VisitListNotifier(repository, ref);
});
