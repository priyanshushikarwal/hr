import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/config/hive_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/offline_queue_manager.dart';
import '../models/task_model.dart';

/// Task Repository — Dual Data Layer (Appwrite + Hive)
class TaskRepository {
  final Databases _databases;

  TaskRepository() : _databases = AppwriteService.instance.databases;

  static const _collectionId = AppwriteConfig.tasksCollectionId;
  static const _boxName = HiveBoxes.tasks;

  // ==== CREATE ====

  Future<Task> createTask(
    String title, {
    String? description,
    required DateTime dueDate,
    required String createdBy,
    String? assignedTo,
    String priority = 'medium',
    required bool isOnline,
  }) async {
    final taskId = const Uuid().v4();
    final now = DateTime.now();

    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': 'pending',
      'priority': priority,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    if (isOnline) {
      try {
        final response = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: taskId,
          data: data,
        );

        final task = Task.fromJson({...response.data, 'id': response.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(task.id, task.toJson());
        return task;
      } on AppwriteException catch (e) {
        // Fallback to Hive + offline queue
        final task = Task.fromJson({...data, 'id': taskId});
        final box = HiveService.getBox(_boxName);
        await box.put(task.id, task.toJson());
        await OfflineQueueManager.instance.enqueue(
          OfflineOperation(
            id: const Uuid().v4(),
            collection: _collectionId,
            type: 'create',
            documentId: taskId,
            data: data,
            timestamp: now,
          ),
        );
        return task;
      }
    } else {
      final task = Task.fromJson({...data, 'id': taskId});
      final box = HiveService.getBox(_boxName);
      await box.put(task.id, task.toJson());
      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'create',
          documentId: taskId,
          data: data,
          timestamp: now,
        ),
      );
      return task;
    }
  }

  // ==== READ ====

  Future<List<Task>> getTasks({
    DateTime? filterDate,
    String? status,
    String? assignedTo,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final queries = <String>[
          Query.limit(500),
          Query.orderDesc('dueDate'),
        ];

        if (status != null && status.isNotEmpty) {
          queries.add(Query.equal('status', status));
        }

        if (assignedTo != null) {
          queries.add(Query.equal('assignedTo', assignedTo));
        }

        final response = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          queries: queries,
        );

        final tasks = response.documents
            .map((doc) => Task.fromJson({...doc.data, 'id': doc.$id}))
            .toList();

        // Cache to Hive
        final box = HiveService.getBox(_boxName);
        for (final task in tasks) {
          await box.put(task.id, task.toJson());
        }

        return tasks;
      } on AppwriteException catch (e) {
        print('TaskRepository error: ${e.message}');
        return _getFromHive(filterDate: filterDate, status: status, assignedTo: assignedTo);
      }
    } else {
      return _getFromHive(filterDate: filterDate, status: status, assignedTo: assignedTo);
    }
  }

  List<Task> _getFromHive({DateTime? filterDate, String? status, String? assignedTo}) {
    final box = HiveService.getBox(_boxName);
    var tasks = box.values
        .map((v) => Task.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    if (filterDate != null) {
      tasks = tasks.where((t) {
        final dueDay = t.dueDate.day;
        final filterDay = filterDate.day;
        final dueMonth = t.dueDate.month;
        final filterMonth = filterDate.month;
        final dueYear = t.dueDate.year;
        final filterYear = filterDate.year;
        return dueDay == filterDay && dueMonth == filterMonth && dueYear == filterYear;
      }).toList();
    }

    if (status != null && status.isNotEmpty) {
      tasks = tasks.where((t) => t.status.name == status).toList();
    }

    if (assignedTo != null) {
      tasks = tasks.where((t) => t.assignedTo == assignedTo).toList();
    }

    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  Future<Task?> getTaskById(String taskId, {required bool isOnline}) async {
    if (isOnline) {
      try {
        final doc = await _databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: taskId,
        );
        return Task.fromJson({...doc.data, 'id': doc.$id});
      } catch (e) {
        return _getFromHiveById(taskId);
      }
    } else {
      return _getFromHiveById(taskId);
    }
  }

  Task? _getFromHiveById(String taskId) {
    final box = HiveService.getBox(_boxName);
    final data = box.get(taskId);
    if (data != null) {
      return Task.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // ==== UPDATE ====

  Future<Task> updateTask(
    String taskId,
    Map<String, dynamic> updates, {
    required bool isOnline,
  }) async {
    final now = DateTime.now();
    final updateData = {
      ...updates,
      'updatedAt': now.toIso8601String(),
    };

    if (isOnline) {
      try {
        final doc = await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: taskId,
          data: updateData,
        );

        final task = Task.fromJson({...doc.data, 'id': doc.$id});
        final box = HiveService.getBox(_boxName);
        await box.put(task.id, task.toJson());
        return task;
      } on AppwriteException catch (e) {
        // Fallback to Hive + offline queue
        final existing = await _getFromHiveById(taskId);
        if (existing != null) {
          final updated = existing.copyWith(
            status: _parseStatus(updateData['status']),
            priority: _parsePriority(updateData['priority']),
            assignedTo: updateData['assignedTo'],
            completedAt: updateData['completedAt'],
            completedBy: updateData['completedBy'],
          );
          final box = HiveService.getBox(_boxName);
          await box.put(updated.id, updated.toJson());

          await OfflineQueueManager.instance.enqueue(
            OfflineOperation(
              id: const Uuid().v4(),
              collection: _collectionId,
              type: 'update',
              documentId: taskId,
              data: updateData,
              timestamp: now,
            ),
          );

          return updated;
        }
        rethrow;
      }
    } else {
      final existing = await _getFromHiveById(taskId);
      if (existing != null) {
        final updated = existing.copyWith(
          status: _parseStatus(updateData['status']),
          priority: _parsePriority(updateData['priority']),
          assignedTo: updateData['assignedTo'],
          completedAt: updateData['completedAt'],
          completedBy: updateData['completedBy'],
        );
        final box = HiveService.getBox(_boxName);
        await box.put(updated.id, updated.toJson());

        await OfflineQueueManager.instance.enqueue(
          OfflineOperation(
            id: const Uuid().v4(),
            collection: _collectionId,
            type: 'update',
            documentId: taskId,
            data: updateData,
            timestamp: now,
          ),
        );

        return updated;
      }
      throw Exception('Task not found');
    }
  }

  Future<void> markTaskComplete(
    String taskId,
    String completedBy, {
    required bool isOnline,
  }) async {
    await updateTask(
      taskId,
      {
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
        'completedBy': completedBy,
      },
      isOnline: isOnline,
    );
  }

  // ==== DELETE ====

  Future<void> deleteTask(String taskId, {required bool isOnline}) async {
    if (isOnline) {
      try {
        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: _collectionId,
          documentId: taskId,
        );

        final box = HiveService.getBox(_boxName);
        await box.delete(taskId);
      } on AppwriteException catch (e) {
        // Still remove from local storage
        final box = HiveService.getBox(_boxName);
        await box.delete(taskId);

        await OfflineQueueManager.instance.enqueue(
          OfflineOperation(
            id: const Uuid().v4(),
            collection: _collectionId,
            type: 'delete',
            documentId: taskId,
            data: {},
            timestamp: DateTime.now(),
          ),
        );
      }
    } else {
      final box = HiveService.getBox(_boxName);
      await box.delete(taskId);

      await OfflineQueueManager.instance.enqueue(
        OfflineOperation(
          id: const Uuid().v4(),
          collection: _collectionId,
          type: 'delete',
          documentId: taskId,
          data: {},
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // ==== HELPERS ====

  static TaskStatus _parseStatus(dynamic value) {
    if (value == null) return TaskStatus.pending;
    if (value is TaskStatus) return value;
    if (value is String) {
      return TaskStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskStatus.pending,
      );
    }
    return TaskStatus.pending;
  }

  static TaskPriority _parsePriority(dynamic value) {
    if (value == null) return TaskPriority.medium;
    if (value is TaskPriority) return value;
    if (value is String) {
      return TaskPriority.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskPriority.medium,
      );
    }
    return TaskPriority.medium;
  }
}
