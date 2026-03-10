import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/employee_model.dart';

/// Employee Repository — Dual Data Layer (Appwrite + Hive)
class EmployeeRepository {
  final Databases _databases;

  EmployeeRepository() : _databases = AppwriteService.instance.databases;

  static const _collectionId = AppwriteConfig.employeesCollectionId;
  static const _boxName = HiveBoxes.employees;

  // ============================
  // READ Operations
  // ============================

  /// Get all employees — tries Appwrite first, falls back to Hive
  Future<List<Employee>> getEmployees({
    int limit = 100,
    int offset = 0,
    String? status,
    String? department,
    String? employeeType,
    String? searchQuery,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final queries = <String>[
          Query.limit(limit),
          Query.offset(offset),
          Query.orderDesc('\$createdAt'),
        ];
        if (status != null && status.isNotEmpty)
          queries.add(Query.equal('status', status));
        if (department != null && department.isNotEmpty)
          queries.add(Query.equal('department', department));
        if (employeeType != null && employeeType.isNotEmpty)
          queries.add(Query.equal('employeeType', employeeType));
        if (searchQuery != null && searchQuery.isNotEmpty)
          queries.add(Query.search('name', searchQuery));

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );

        final employees = response.documents
            .map((doc) => Employee.fromJson({...doc.data, 'id': doc.$id}))
            .toList();

        // Cache to Hive
        final box = HiveService.getBox(_boxName);
        for (final emp in employees) {
          await box.put(emp.id, emp.toJson());
        }

        return employees;
      } on AppwriteException catch (e) {
        // Fallback to Hive on error
        print('EmployeeRepository.getEmployees Appwrite error: ${e.message}');
        return _getFromHive();
      }
    } else {
      return _getFromHive(
        status: status,
        department: department,
        employeeType: employeeType,
      );
    }
  }

  /// Get from Hive with optional filters
  List<Employee> _getFromHive({
    String? status,
    String? department,
    String? employeeType,
  }) {
    final box = HiveService.getBox(_boxName);
    var employees = box.values
        .map((v) => Employee.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    if (status != null && status.isNotEmpty) {
      employees = employees
          .where((e) => e.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    if (department != null && department.isNotEmpty) {
      employees = employees.where((e) => e.department == department).toList();
    }
    if (employeeType != null && employeeType.isNotEmpty) {
      employees = employees
          .where((e) => e.employeeType == employeeType)
          .toList();
    }

    return employees;
  }

  /// Get employee by document ID
  Future<Employee?> getEmployeeById(
    String employeeId, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: [Query.equal('employeeId', employeeId), Query.limit(1)],
        );
        if (response.documents.isEmpty) return null;
        final doc = response.documents.first;
        return Employee.fromJson({...doc.data, 'id': doc.$id});
      } on AppwriteException {
        return _getEmployeeFromHive(employeeId);
      }
    } else {
      return _getEmployeeFromHive(employeeId);
    }
  }

  Employee? _getEmployeeFromHive(String employeeId) {
    final box = HiveService.getBox(_boxName);
    for (final v in box.values) {
      final map = Map<String, dynamic>.from(v);
      if (map['employeeId'] == employeeId || map['id'] == employeeId) {
        return Employee.fromJson(map);
      }
    }
    return null;
  }

  // ============================
  // CREATE
  // ============================

  Future<Employee> createEmployee(
    Employee employee, {
    required bool isOnline,
    String? password,
  }) async {
    final data = employee.toJson()..remove('id');
    // We explicitly generate an ID so we can match it in Auth and Users
    final docId = const Uuid().v4().replaceAll('-', '').substring(0, 20);

    if (isOnline) {
      try {
        // 1. Create Appwrite Auth User (if password provided)
        if (password != null &&
            password.isNotEmpty &&
            employee.email.isNotEmpty) {
          final uri = Uri.parse('${AppwriteConfig.endpoint}/users');
          // Bypass SSL verification for the API call to avoid Handshake exceptions
          final httpClient = HttpClient()
            ..badCertificateCallback =
                ((X509Certificate cert, String host, int port) => true);
          final ioClient = IOClient(httpClient);

          final response = await ioClient.post(
            uri,
            headers: {
              'X-Appwrite-Project': AppwriteConfig.projectId,
              'X-Appwrite-Key':
                  'standard_207fdbbe0325c8ba58258ef2ed923252116f1c91011c4372ca6575d3a640d19128f5e2e1f8e817349c2c82f981861bf6c1160f72273f303168dd7a660ffe2a7a4c6e59db15d657e8f756e78c0185b1a2994687dbb66b09cf21c484619ded198429ca25d56d7c697ce8aaf1d07d417d403ae823a829f51cdf5f82ef7831c37c76', // From setup_appwrite.dart
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': docId,
              'email': employee.email,
              'password': password,
              'name': '${employee.firstName} ${employee.lastName}',
            }),
          );

          if (response.statusCode >= 400) {
            throw AppwriteException(response.body);
          }

          // 2. Create User Role map in `users` collection
          await _databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollectionId,
            documentId: docId,
            data: {
              'userId': docId,
              'email': employee.email,
              'name': '${employee.firstName} ${employee.lastName}',
              'role': 'employee',
              'phone': employee.phone,
              'status': 'active',
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
        }

        // 3. Create Employee profile
        data['employeeId'] = docId; // Store link to Auth ID

        final doc = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: docId,
          data: data,
        );
        final result = Employee.fromJson({...doc.data, 'id': doc.$id});
        // Save to Hive
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create employee: ${e.message}');
      }
    } else {
      // Save locally and queue
      final docId = const Uuid().v4();
      final localEmployee = employee.copyWith(id: docId);
      final box = HiveService.getBox(_boxName);
      await box.put(docId, localEmployee.toJson());

      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'create',
          documentId: docId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );

      return localEmployee;
    }
  }

  // ============================
  // UPDATE
  // ============================

  Future<Employee> updateEmployee(
    String documentId,
    Map<String, dynamic> data, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: documentId,
          data: data,
        );
        final result = Employee.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(result.id, result.toJson());
        return result;
      } on AppwriteException catch (e) {
        throw Exception('Failed to update employee: ${e.message}');
      }
    } else {
      // Update in Hive and queue
      final box = HiveService.getBox(_boxName);
      final existing = box.get(documentId);
      if (existing != null) {
        final updated = {...Map<String, dynamic>.from(existing), ...data};
        await box.put(documentId, updated);
      }

      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'update',
          documentId: documentId,
          data: data,
          timestamp: DateTime.now(),
        ),
      );

      final updatedMap = box.get(documentId);
      return Employee.fromJson(Map<String, dynamic>.from(updatedMap!));
    }
  }

  // ============================
  // DELETE (Soft Delete)
  // ============================

  Future<void> deactivateEmployee(
    String documentId, {
    required bool isOnline,
  }) async {
    await updateEmployee(documentId, {
      'status': 'Inactive',
    }, isOnline: isOnline);
  }

  // ============================
  // DELETE (Hard Delete)
  // ============================

  Future<void> deleteEmployee(
    String documentId, {
    required bool isOnline,
  }) async {
    // Remove from Hive
    final box = HiveService.getBox(_boxName);
    await box.delete(documentId);

    if (isOnline) {
      try {
        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to delete employee: ${e.message}');
      }
    } else {
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'delete',
          documentId: documentId,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // ============================
  // COUNT
  // ============================

  Future<int> getEmployeeCount({String? status, required bool isOnline}) async {
    if (isOnline) {
      try {
        final queries = <String>[];
        if (status != null) queries.add(Query.equal('status', status));
        queries.add(Query.limit(1));

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );
        return response.total;
      } on AppwriteException {
        return _countFromHive(status: status);
      }
    } else {
      return _countFromHive(status: status);
    }
  }

  int _countFromHive({String? status}) {
    final box = HiveService.getBox(_boxName);
    if (status == null) return box.length;
    return box.values.where((v) {
      final map = Map<String, dynamic>.from(v);
      return (map['status'] as String?)?.toLowerCase() == status.toLowerCase();
    }).length;
  }
}
