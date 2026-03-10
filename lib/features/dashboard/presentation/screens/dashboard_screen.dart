import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';
import '../../../../core/utils/dummy_data.dart';
import '../../../../core/services/appwrite_service.dart';
import '../widgets/dashboard_charts.dart';
import '../../../employees/domain/providers/employee_providers.dart';

/// Dashboard Screen - Main landing page after login
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesState = ref.watch(employeeListProvider);
    final employees = employeesState.employees;

    final total = employees.length;
    final officeCount = employees.where((e) => e.isOffice).length;
    final factoryCount = employees.where((e) => e.isFactory).length;
    final activeCount = employees.where((e) => e.isActive).length;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Welcome back! 👋',
            subtitle: 'Here\'s what\'s happening with your team today.',
            actions: [
              SecondaryButton(
                text: 'Send a ping',
                icon: AppIcons.check,
                onPressed: () async {
                  try {
                    await client.ping();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ping successful!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ping failed: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              SecondaryButton(
                text: 'Download Report',
                icon: AppIcons.download,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Add Employee',
                icon: AppIcons.userAdd,
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Stats Row — DYNAMIC from real employee data
          DashboardGrid(
            columns: 4,
            children: [
              StatCard(
                title: 'TOTAL EMPLOYEES',
                value: total.toString(),
                subtitle: '$activeCount active',
                icon: AppIcons.employees,
                iconColor: AppColors.primary,
                trend: total > 0 ? '+$total' : '0',
                isTrendPositive: total > 0,
              ),
              StatCard(
                title: 'OFFICE EMPLOYEES',
                value: officeCount.toString(),
                subtitle: 'Regular staff',
                icon: AppIcons.office,
                iconColor: AppColors.secondary,
              ),
              StatCard(
                title: 'FACTORY EMPLOYEES',
                value: factoryCount.toString(),
                subtitle: 'Production team',
                icon: AppIcons.factory,
                iconColor: AppColors.accent,
              ),
              StatCard(
                title: 'PENDING APPROVALS',
                value: '0',
                subtitle: 'Requires action',
                icon: AppIcons.pending,
                iconColor: AppColors.warning,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Charts Row
          _buildChartsSection(employees),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Bottom Row - Activities & Tasks
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildChartsSection(List employees) {
    // Build department distribution from real data
    final deptMap = <String, int>{};
    for (final emp in employees) {
      deptMap[emp.department] = (deptMap[emp.department] ?? 0) + 1;
    }

    return TwoColumnLayout(
      leftFlex: 3,
      rightFlex: 2,
      left: Column(
        children: [
          // Attendance Chart
          ContentCard(
            height: 320,
            title: 'Attendance Trend',
            titleAction: GhostButton(text: 'View Details', onPressed: () {}),
            child: AttendanceChart(data: DummyData.monthlyAttendance),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          // Salary Chart
          ContentCard(
            height: 280,
            title: 'Monthly Salary Expense',
            titleAction: GhostButton(text: 'View Report', onPressed: () {}),
            child: SalaryExpenseChart(data: DummyData.monthlySalaryExpense),
          ),
        ],
      ),
      right: Column(
        children: [
          // Quick Stats
          _buildQuickStats(employees),
          const SizedBox(height: AppSpacing.cardGap),
          // Department Distribution
          ContentCard(
            height: 320,
            title: 'Department Distribution',
            child: deptMap.isNotEmpty
                ? DepartmentPieChart(data: deptMap)
                : Center(
                    child: Text(
                      'Add employees to see distribution',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List employees) {
    final pfPending = employees
        .where((e) => e.isActive && !e.isPfApplicable)
        .length;
    final esicPending = employees
        .where((e) => e.isActive && !e.isEsicApplicable)
        .length;

    return ContentCard(
      title: 'This Month',
      child: Column(
        children: [
          _QuickStatItem(
            icon: AppIcons.money,
            label: 'Salary Processed',
            value: '₹0',
            color: AppColors.success,
          ),
          const Divider(height: 24),
          _QuickStatItem(
            icon: AppIcons.pf,
            label: 'PF Pending',
            value: '$pfPending employees',
            color: AppColors.warning,
          ),
          const Divider(height: 24),
          _QuickStatItem(
            icon: AppIcons.esic,
            label: 'ESIC Pending',
            value: '$esicPending employees',
            color: AppColors.error,
          ),
          const Divider(height: 24),
          _QuickStatItem(
            icon: AppIcons.attendance,
            label: 'Total Employees',
            value: '${employees.length}',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return TwoColumnLayout(
      left: ContentCard(
        title: 'Recent Activities',
        titleAction: GhostButton(text: 'View All', onPressed: () {}),
        child: Column(
          children: DummyData.recentActivities.map((activity) {
            return _ActivityItem(
              action: activity['action'] as String,
              description: activity['description'] as String,
              time: activity['time'] as String,
              type: activity['type'] as String,
            );
          }).toList(),
        ),
      ),
      right: ContentCard(
        title: 'Pending Tasks',
        titleAction: TextBadge(
          label: '${DummyData.pendingTasks.length} tasks',
          backgroundColor: AppColors.warningSurface,
          textColor: AppColors.warningDark,
        ),
        child: Column(
          children: DummyData.pendingTasks.map((task) {
            return _TaskItem(
              title: task['title'] as String,
              description: task['description'] as String,
              priority: task['priority'] as String,
              dueDate: task['dueDate'] as String,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTypography.labelMedium)),
        Text(value, style: AppTypography.titleSmall.copyWith(color: color)),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String action;
  final String description;
  final String time;
  final String type;

  const _ActivityItem({
    required this.action,
    required this.description,
    required this.time,
    required this.type,
  });

  Color get _iconColor {
    switch (type) {
      case 'add':
        return AppColors.success;
      case 'payment':
        return AppColors.primary;
      case 'document':
        return AppColors.info;
      case 'approval':
        return AppColors.warning;
      case 'upload':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (type) {
      case 'add':
        return AppIcons.userAdd;
      case 'payment':
        return AppIcons.money;
      case 'document':
        return AppIcons.offerLetter;
      case 'approval':
        return AppIcons.check;
      case 'upload':
        return AppIcons.upload;
      default:
        return AppIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, size: 16, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: AppTypography.labelMedium),
                Text(description, style: AppTypography.caption),
              ],
            ),
          ),
          Text(time, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String description;
  final String priority;
  final String dueDate;

  const _TaskItem({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
  });

  Color get _priorityColor {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: _priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMedium),
                Text(description, style: AppTypography.caption),
              ],
            ),
          ),
          TextBadge(
            label: dueDate,
            backgroundColor: _priorityColor.withOpacity(0.1),
            textColor: _priorityColor,
            isSmall: true,
          ),
        ],
      ),
    );
  }
}
