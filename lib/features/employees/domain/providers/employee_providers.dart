import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/employee_model.dart';
import '../../data/repositories/employee_repository.dart';

/// Employee Repository Provider
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

/// Employee List State
class EmployeeListState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;
  final int totalCount;

  const EmployeeListState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
  });

  EmployeeListState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    String? error,
    int? totalCount,
  }) {
    return EmployeeListState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Employee List Notifier
class EmployeeListNotifier extends StateNotifier<EmployeeListState> {
  final EmployeeRepository _repository;
  final Ref _ref;

  EmployeeListNotifier(this._repository, this._ref)
    : super(const EmployeeListState()) {
    loadEmployees();
  }

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadEmployees({
    String? status,
    String? department,
    String? employeeType,
    String? searchQuery,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final employees = await _repository.getEmployees(
        status: status,
        department: department,
        employeeType: employeeType,
        searchQuery: searchQuery,
        isOnline: _isOnline,
      );
      state = EmployeeListState(
        employees: employees,
        totalCount: employees.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createEmployee(Employee employee, {String? password}) async {
    try {
      await _repository.createEmployee(
        employee,
        isOnline: _isOnline,
        password: password,
      );
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateEmployee(String docId, Map<String, dynamic> data) async {
    try {
      await _repository.updateEmployee(docId, data, isOnline: _isOnline);
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deactivateEmployee(String docId) async {
    try {
      await _repository.deactivateEmployee(docId, isOnline: _isOnline);
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteEmployee(String docId) async {
    try {
      await _repository.deleteEmployee(docId, isOnline: _isOnline);
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

/// Employee List Provider
final employeeListProvider =
    StateNotifierProvider<EmployeeListNotifier, EmployeeListState>((ref) {
      final repository = ref.watch(employeeRepositoryProvider);
      return EmployeeListNotifier(repository, ref);
    });

/// Single Employee Provider
final employeeByIdProvider = FutureProvider.family<Employee?, String>((
  ref,
  employeeId,
) async {
  final repository = ref.watch(employeeRepositoryProvider);
  final isOnline = ref.watch(networkStatusProvider) == NetworkStatus.online;
  return await repository.getEmployeeById(employeeId, isOnline: isOnline);
});
