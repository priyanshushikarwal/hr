import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  EmployeeListNotifier(this._repository) : super(const EmployeeListState()) {
    loadEmployees();
  }

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
      );
      state = EmployeeListState(
        employees: employees,
        totalCount: employees.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createEmployee(Employee employee) async {
    try {
      await _repository.createEmployee(employee);
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateEmployee(String docId, Map<String, dynamic> data) async {
    try {
      await _repository.updateEmployee(docId, data);
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deactivateEmployee(String docId) async {
    try {
      await _repository.deactivateEmployee(docId);
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteEmployee(String docId) async {
    try {
      await _repository.deleteEmployee(docId);
      await loadEmployees();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Employee List Provider
final employeeListProvider =
    StateNotifierProvider<EmployeeListNotifier, EmployeeListState>((ref) {
      final repository = ref.watch(employeeRepositoryProvider);
      return EmployeeListNotifier(repository);
    });

/// Single Employee Provider
final employeeByIdProvider = FutureProvider.family<Employee?, String>((
  ref,
  employeeId,
) async {
  final repository = ref.watch(employeeRepositoryProvider);
  return await repository.getEmployeeById(employeeId);
});
