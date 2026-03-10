import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/salary_models.dart';
import '../../data/repositories/salary_repository.dart';

final salaryRepositoryProvider = Provider<SalaryRepository>((ref) {
  return SalaryRepository();
});

// ==========================
// OFFICE SALARY
// ==========================

class OfficeSalaryState {
  final OfficeSalaryStructure? salary;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  const OfficeSalaryState({
    this.salary,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  OfficeSalaryState copyWith({
    OfficeSalaryStructure? salary,
    bool? isLoading,
    String? error,
    bool? isSaving,
  }) {
    return OfficeSalaryState(
      salary: salary ?? this.salary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class OfficeSalaryNotifier extends StateNotifier<OfficeSalaryState> {
  final SalaryRepository _repository;
  final Ref _ref;

  OfficeSalaryNotifier(this._repository, this._ref)
    : super(const OfficeSalaryState());

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadSalary(String employeeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final salary = await _repository.getOfficeSalary(
        employeeId,
        isOnline: _isOnline,
      );
      state = OfficeSalaryState(salary: salary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveSalary(OfficeSalaryStructure salary) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final result = await _repository.saveOfficeSalary(
        salary,
        isOnline: _isOnline,
      );
      state = OfficeSalaryState(salary: result);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      rethrow;
    }
  }

  void clear() {
    state = const OfficeSalaryState();
  }
}

final officeSalaryProvider =
    StateNotifierProvider<OfficeSalaryNotifier, OfficeSalaryState>((ref) {
      final repo = ref.watch(salaryRepositoryProvider);
      return OfficeSalaryNotifier(repo, ref);
    });

// ==========================
// FACTORY SALARY
// ==========================

class FactorySalaryState {
  final List<FactorySalaryEntry> entries;
  final bool isLoading;
  final String? error;
  final int selectedMonth;
  final int selectedYear;

  const FactorySalaryState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    required this.selectedMonth,
    required this.selectedYear,
  });

  FactorySalaryState copyWith({
    List<FactorySalaryEntry>? entries,
    bool? isLoading,
    String? error,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return FactorySalaryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  double get totalAmount => entries.fold(0, (sum, e) => sum + e.totalAmount);
}

class FactorySalaryNotifier extends StateNotifier<FactorySalaryState> {
  final SalaryRepository _repository;
  final Ref _ref;

  FactorySalaryNotifier(this._repository, this._ref)
    : super(
        FactorySalaryState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        ),
      ) {
    loadEntries();
  }

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadEntries({int? month, int? year, String? employeeId}) async {
    final m = month ?? state.selectedMonth;
    final y = year ?? state.selectedYear;
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedMonth: m,
      selectedYear: y,
    );

    try {
      final entries = await _repository.getFactorySalaryEntries(
        month: m,
        year: y,
        employeeId: employeeId,
        isOnline: _isOnline,
      );
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createEntry(FactorySalaryEntry entry) async {
    try {
      await _repository.createFactoryEntry(entry, isOnline: _isOnline);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateEntry(String docId, Map<String, dynamic> data) async {
    try {
      await _repository.updateFactoryEntry(docId, data, isOnline: _isOnline);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteEntry(String docId) async {
    try {
      await _repository.deleteFactoryEntry(docId, isOnline: _isOnline);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final factorySalaryProvider =
    StateNotifierProvider<FactorySalaryNotifier, FactorySalaryState>((ref) {
      final repo = ref.watch(salaryRepositoryProvider);
      return FactorySalaryNotifier(repo, ref);
    });

/// All salary structures provider (for reports)
final allSalaryStructuresProvider = FutureProvider<List<OfficeSalaryStructure>>(
  (ref) async {
    final repo = ref.watch(salaryRepositoryProvider);
    final isOnline = ref.watch(networkStatusProvider) == NetworkStatus.online;
    return repo.getAllOfficeSalaries(isOnline: isOnline);
  },
);
