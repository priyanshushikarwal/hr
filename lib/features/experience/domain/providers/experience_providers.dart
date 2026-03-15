import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/experience_model.dart';
import '../../data/repositories/experience_repository.dart';

/// Provider for Experience Repository
final experienceRepositoryProvider = Provider((ref) => ExperienceRepository());

/// State class for Experience
class ExperienceState {
  final List<WorkExperience> records;
  final int internalDays;
  final bool isLoading;
  final String? error;

  ExperienceState({
    this.records = const [],
    this.internalDays = 0,
    this.isLoading = false,
    this.error,
  });

  ExperienceState copyWith({
    List<WorkExperience>? records,
    int? internalDays,
    bool? isLoading,
    String? error,
  }) {
    return ExperienceState(
      records: records ?? this.records,
      internalDays: internalDays ?? this.internalDays,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing experience state
class ExperienceNotifier extends StateNotifier<ExperienceState> {
  final ExperienceRepository _repository;

  ExperienceNotifier(this._repository) : super(ExperienceState());

  Future<void> loadExperience(String employeeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await _repository.getEmployeeExperience(employeeId);
      final internalDays = await _repository.getTotalPresentDays(employeeId);
      state = state.copyWith(records: records, internalDays: internalDays, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addExperience(WorkExperience experience) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newRecord = await _repository.createExperience(experience);
      state = state.copyWith(
        records: [newRecord, ...state.records],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateExperience(WorkExperience experience) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateExperience(experience);
      state = state.copyWith(
        records: state.records.map((r) => r.id == updated.id ? updated : r).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteExperience(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteExperience(id);
      state = state.copyWith(
        records: state.records.where((r) => r.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

/// Provider for Experience Notifier
final experienceProvider = StateNotifierProvider<ExperienceNotifier, ExperienceState>((ref) {
  final repo = ref.watch(experienceRepositoryProvider);
  return ExperienceNotifier(repo);
});

/// Auto-fetch provider for a specific employee
final employeeExperienceProvider = FutureProvider.family<List<WorkExperience>, String>((ref, employeeId) async {
  final repo = ref.watch(experienceRepositoryProvider);
  return repo.getEmployeeExperience(employeeId);
});
