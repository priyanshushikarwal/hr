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
// ==========================
// ADVANCE SALARY
// ==========================

class AdvanceSalaryState {
  final List<AdvanceSalary> advances;
  final bool isLoading;
  final String? error;
  final bool isSaving;
  final AdvanceSalary? selectedAdvance;

  const AdvanceSalaryState({
    this.advances = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
    this.selectedAdvance,
  });

  AdvanceSalaryState copyWith({
    List<AdvanceSalary>? advances,
    bool? isLoading,
    String? error,
    bool? isSaving,
    AdvanceSalary? selectedAdvance,
  }) {
    return AdvanceSalaryState(
      advances: advances ?? this.advances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSaving: isSaving ?? this.isSaving,
      selectedAdvance: selectedAdvance ?? this.selectedAdvance,
    );
  }

  /// Get pending amount across all active advances
  double get totalPendingAmount {
    return advances
        .where((adv) => adv.status == 'approved' || adv.status == 'partial')
        .fold(0, (prev, adv) => prev + adv.pendingAmount);
  }

  /// Get total approved advances
  double get totalApprovedAmount {
    return advances
        .where((adv) =>
            adv.status == 'approved' ||
            adv.status == 'partial' ||
            adv.status == 'cleared')
        .fold(0, (prev, adv) => prev + adv.advanceAmount);
  }

  /// Get count of pending advances (not yet cleared)
  int get pendingCount {
    return advances
        .where((adv) => adv.status == 'approved' || adv.status == 'partial')
        .length;
  }
}

class AdvanceSalaryNotifier extends StateNotifier<AdvanceSalaryState> {
  final SalaryRepository _repository;
  final Ref _ref;

  AdvanceSalaryNotifier(this._repository, this._ref)
    : super(const AdvanceSalaryState());

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  /// Load all advances for an employee
  Future<void> loadEmployeeAdvances(String employeeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final advances = await _repository.getEmployeeAdvances(
        employeeId,
        isOnline: _isOnline,
      );
      state = state.copyWith(advances: advances, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create new advance request
  Future<AdvanceSalary> createAdvanceRequest(AdvanceSalary advance) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final result = await _repository.createAdvance(
        advance,
        isOnline: _isOnline,
      );
      state = state.copyWith(
        advances: [...state.advances, result],
        isSaving: false,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      rethrow;
    }
  }

  /// Approve an advance request
  Future<void> approveAdvance(
    String advanceId,
    String approvedBy, {
    String? remarks,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final index =
          state.advances.indexWhere((adv) => adv.id == advanceId);
      if (index == -1) throw Exception('Advance not found');

      final advance = state.advances[index];
      final updated = advance.copyWith(
        status: 'approved',
        approvalDate: DateTime.now(),
        approvedBy: approvedBy,
        remarks: remarks ?? advance.remarks,
        updatedAt: DateTime.now(),
      );

      await _repository.updateAdvance(
        advanceId,
        updated,
        isOnline: _isOnline,
      );

      final newAdvances = [...state.advances];
      newAdvances[index] = updated;
      state = state.copyWith(advances: newAdvances, isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      rethrow;
    }
  }

  /// Record advance deduction from salary
  Future<void> recordAdvanceDeduction(
    String advanceId,
    double deductionAmount,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final updated = await _repository.recordAdvanceDeduction(
        advanceId,
        deductionAmount,
        isOnline: _isOnline,
      );

      final index = state.advances.indexWhere((adv) => adv.id == advanceId);
      if (index != -1) {
        final newAdvances = [...state.advances];
        newAdvances[index] = updated;
        state = state.copyWith(advances: newAdvances, isSaving: false);
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      rethrow;
    }
  }

  /// Get total pending advance amount for salary deduction
  Future<double> getTotalPendingAmount(String employeeId) async {
    try {
      return await _repository.getTotalPendingAdvanceAmount(
        employeeId,
        isOnline: _isOnline,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  void clear() {
    state = const AdvanceSalaryState();
  }
}

final advanceSalaryProvider =
    StateNotifierProvider<AdvanceSalaryNotifier, AdvanceSalaryState>((ref) {
      final repo = ref.watch(salaryRepositoryProvider);
      return AdvanceSalaryNotifier(repo, ref);
    });

/// Get pending advances for an employee
final employeeAdvancesProvider =
    FutureProvider.family<List<AdvanceSalary>, String>((ref, employeeId) async {
  final repo = ref.watch(salaryRepositoryProvider);
  final isOnline = ref.watch(networkStatusProvider) == NetworkStatus.online;
  return repo.getEmployeeAdvances(employeeId, isOnline: isOnline);
});

/// Get total pending advance amount for salary deduction
final totalPendingAdvanceProvider =
    FutureProvider.family<double, String>((ref, employeeId) async {
  final repo = ref.watch(salaryRepositoryProvider);
  final isOnline = ref.watch(networkStatusProvider) == NetworkStatus.online;
  return repo.getTotalPendingAdvanceAmount(employeeId, isOnline: isOnline);
});

/// Get all pending advances across all employees
final allPendingAdvancesProvider = FutureProvider<List<AdvanceSalary>>(
  (ref) async {
    final repo = ref.watch(salaryRepositoryProvider);
    final isOnline = ref.watch(networkStatusProvider) == NetworkStatus.online;
    return repo.getPendingAdvances(isOnline: isOnline);
  },
);