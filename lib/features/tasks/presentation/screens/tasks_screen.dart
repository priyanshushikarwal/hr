import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../shared/layouts/header.dart';
import '../../data/models/task_model.dart';
import '../../domain/providers/task_providers.dart';
import '../widgets/add_task_dialog.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const AppHeader(
              title: 'Task Management',
              subtitle: 'Create, track, and manage daily tasks for your team',
            ),

            const SizedBox(height: 24),

            // Summary Cards
            _buildSummaryCards(taskState),

            const SizedBox(height: 24),

            // Separator
            Container(
              height: 1,
              color: AppColors.border,
            ),

            const SizedBox(height: 24),

            // Filter Tabs
            _buildFilterTabs(taskState),

            const SizedBox(height: 20),

            // Task List
            if (taskState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (taskState.filteredTasks.isEmpty)
              _buildEmptyState(taskState)
            else
              _buildTasksList(taskState),

            const SizedBox(height: 40),
          ],
        ),
    );
  }

  Widget _buildSummaryCards(TaskListState state) {
    return Row(
      children: [
        _SummaryCard(
          label: 'Total Tasks',
          value: state.tasks.length.toString(),
          icon: AppIcons.check,
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          label: 'Pending',
          value: state.pendingCount.toString(),
          icon: AppIcons.clock,
          color: AppColors.warning,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          label: 'Completed',
          value: state.completedCount.toString(),
          icon: AppIcons.check,
          color: AppColors.success,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          label: "Today's",
          value: state.todaysTasks.length.toString(),
          icon: AppIcons.calendar,
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildFilterTabs(TaskListState state) {
    return Row(
      children: [
        _FilterTab(
          label: 'All Tasks',
          isActive: state.selectedFilter == 'all',
          onTap: () {
            ref.read(taskListProvider.notifier).setFilter('all');
          },
        ),
        const SizedBox(width: 12),
        _FilterTab(
          label: 'Pending',
          isActive: state.selectedFilter == 'pending',
          onTap: () {
            ref.read(taskListProvider.notifier).setFilter('pending');
          },
        ),
        const SizedBox(width: 12),
        _FilterTab(
          label: 'Completed',
          isActive: state.selectedFilter == 'completed',
          onTap: () {
            ref.read(taskListProvider.notifier).setFilter('completed');
          },
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Task'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddTaskDialog(),
            ).then((_) {
              ref.read(taskListProvider.notifier).loadTasks();
            });
          },
        ),
      ],
    );
  }

  Widget _buildTasksList(TaskListState state) {
    final tasks = state.filteredTasks;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
          task: task,
          onMarkComplete: () {
            ref.read(taskListProvider.notifier).markTaskComplete(
                  task.id,
                  'current_user_id', // TODO: Get from auth context
                );
          },
          onDelete: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete Task'),
                content: const Text('Are you sure you want to delete this task?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(taskListProvider.notifier).deleteTask(task.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(TaskListState state) {
    String message = 'No tasks';
    if (state.selectedFilter == 'pending') {
      message = 'No pending tasks. Great job! 🎉';
    } else if (state.selectedFilter == 'completed') {
      message = 'No completed tasks yet';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              AppIcons.check,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onMarkComplete;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onMarkComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = task.dueDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              if (value == true) {
                onMarkComplete();
              }
            },
            activeColor: AppColors.success,
          ),

          const SizedBox(width: 12),

          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      task.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _priorityColor(task.priority)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priorityLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _priorityColor(task.priority),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Due Date
                    Icon(
                      AppIcons.calendar,
                      size: 12,
                      color: task.isOverdue
                          ? AppColors.error
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd').format(task.dueDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: task.isOverdue
                            ? AppColors.error
                            : AppColors.textTertiary,
                        fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (daysUntilDue >= 0 && daysUntilDue <= 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          daysUntilDue == 0
                              ? 'Today'
                              : 'In ${daysUntilDue}d',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action Buttons
          IconButton(
            icon: const Icon(Icons.delete_outline),
            iconSize: 18,
            color: AppColors.error,
            onPressed: onDelete,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }
}
