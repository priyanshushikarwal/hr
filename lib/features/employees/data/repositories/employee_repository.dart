import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/employee_model.dart';

/// Employee Repository - CRUD operations via Appwrite
class EmployeeRepository {
  final Databases _databases;

  EmployeeRepository() : _databases = AppwriteService.instance.databases;

  /// Get all employees
  Future<List<Employee>> getEmployees({
    int limit = 100,
    int offset = 0,
    String? status,
    String? department,
    String? employeeType,
    String? searchQuery,
  }) async {
    try {
      final queries = <String>[
        Query.limit(limit),
        Query.offset(offset),
        Query.orderDesc('createdAt'),
      ];

      if (status != null && status.isNotEmpty) {
        queries.add(Query.equal('status', status));
      }
      if (department != null && department.isNotEmpty) {
        queries.add(Query.equal('department', department));
      }
      if (employeeType != null && employeeType.isNotEmpty) {
        queries.add(Query.equal('employeeType', employeeType));
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queries.add(Query.search('name', searchQuery));
      }

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        queries: queries,
      );

      return response.documents
          .map((doc) => Employee.fromJson({...doc.data, 'id': doc.$id}))
          .toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch employees: ${e.message}');
    }
  }

  /// Get employee by ID
  Future<Employee?> getEmployeeById(String employeeId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        queries: [Query.equal('employeeId', employeeId), Query.limit(1)],
      );

      if (response.documents.isEmpty) return null;
      final doc = response.documents.first;
      return Employee.fromJson({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch employee: ${e.message}');
    }
  }

  /// Get employee by document ID
  Future<Employee> getEmployeeByDocId(String documentId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        documentId: documentId,
      );
      return Employee.fromJson({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch employee: ${e.message}');
    }
  }

  /// Create new employee
  Future<Employee> createEmployee(Employee employee) async {
    try {
      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        documentId: ID.unique(),
        data: employee.toJson()..remove('id'),
      );
      return Employee.fromJson({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      throw Exception('Failed to create employee: ${e.message}');
    }
  }

  /// Update employee
  Future<Employee> updateEmployee(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        documentId: documentId,
        data: data,
      );
      return Employee.fromJson({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      throw Exception('Failed to update employee: ${e.message}');
    }
  }

  /// Delete employee (soft delete - set status to inactive)
  Future<void> deactivateEmployee(String documentId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        documentId: documentId,
        data: {'status': 'inactive'},
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to deactivate employee: ${e.message}');
    }
  }

  /// Hard delete employee from database
  Future<void> deleteEmployee(String documentId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        documentId: documentId,
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to delete employee: ${e.message}');
    }
  }

  /// Get employee count by status
  Future<int> getEmployeeCount({String? status}) async {
    try {
      final queries = <String>[];
      if (status != null) {
        queries.add(Query.equal('status', status));
      }
      queries.add(Query.limit(1));

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        queries: queries,
      );
      return response.total;
    } on AppwriteException {
      return 0;
    }
  }
}
