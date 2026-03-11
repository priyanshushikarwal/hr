import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider((ref) => TaskRepository());

class TaskListState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final String? selectedFilter; // 'all', 'pending', 'completed'

  TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'all',
  });

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    String? selectedFilter,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  int get pendingCount =>
      tasks.where((t) => t.status == TaskStatus.pending).length;
  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.completed).length;
  List<Task> get filteredTasks => selectedFilter == 'pending'
      ? tasks.where((t) => t.status == TaskStatus.pending).toList()
      : selectedFilter == 'completed'
          ? tasks.where((t) => t.status == TaskStatus.completed).toList()
          : tasks;
  List<Task> get todaysTasks {
    final today = DateTime.now();
    return tasks
        .where((t) =>
            t.dueDate.day == today.day &&
            t.dueDate.month == today.month &&
            t.dueDate.year == today.year)
        .toList();
  }

  List<Task> get overdueTasks =>
      tasks.where((t) => t.isOverdue).toList();
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repository;
  final Ref _ref;

  TaskListNotifier(this._repository, this._ref) : super(TaskListState());

  Future<void> loadTasks({String? filterDate}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isOnline = _ref.read(networkServiceProvider).isConnected;

      DateTime? parsedDate;
      if (filterDate != null) {
        parsedDate = DateTime.tryParse(filterDate);
      }

      final tasks = await _repository.getTasks(
        filterDate: parsedDate,
        isOnline: isOnline,
      );

      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createTask(
    String title, {
    String? description,
    required DateTime dueDate,
    required String createdBy,
    String? assignedTo,
    String priority = 'medium',
  }) async {
    try {
      final isOnline = _ref.read(networkServiceProvider).isConnected;

      final newTask = await _repository.createTask(
        title,
        description: description,
        dueDate: dueDate,
        createdBy: createdBy,
        assignedTo: assignedTo,
        priority: priority,
        isOnline: isOnline,
      );

      state = state.copyWith(tasks: [...state.tasks, newTask]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final isOnline = _ref.read(networkServiceProvider).isConnected;

      await _repository.deleteTask(taskId, isOnline: isOnline);

      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markTaskComplete(String taskId, String completedBy) async {
    try {
      final isOnline = _ref.read(networkServiceProvider).isConnected;

      await _repository.markTaskComplete(taskId, completedBy, isOnline: isOnline);

      state = state.copyWith(
        tasks: state.tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(
              status: TaskStatus.completed,
              completedAt: DateTime.now().toIso8601String(),
              completedBy: completedBy,
            );
          }
          return t;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}

/// Task List Provider
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repository, ref);
});
