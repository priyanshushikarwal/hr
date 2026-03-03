import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

/// Dashboard Screen - Main landing page after login
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

          // Stats Row
          _buildStatsSection(),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Charts Row
          _buildChartsSection(),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Bottom Row - Activities & Tasks
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return DashboardGrid(
      columns: 4,
      children: [
        StatCard(
          title: 'TOTAL EMPLOYEES',
          value: DummyData.totalEmployees.toString(),
          subtitle: '${DummyData.activeEmployees} active',
          icon: AppIcons.employees,
          iconColor: AppColors.primary,
          trend: '+12%',
          isTrendPositive: true,
        ),
        StatCard(
          title: 'OFFICE EMPLOYEES',
          value: DummyData.officeEmployees.toString(),
          subtitle: 'Regular staff',
          icon: AppIcons.office,
          iconColor: AppColors.secondary,
        ),
        StatCard(
          title: 'FACTORY EMPLOYEES',
          value: DummyData.factoryEmployees.toString(),
          subtitle: 'Production team',
          icon: AppIcons.factory,
          iconColor: AppColors.accent,
        ),
        StatCard(
          title: 'PENDING APPROVALS',
          value: DummyData.pendingApprovals.toString(),
          subtitle: 'Requires action',
          icon: AppIcons.pending,
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
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
          _buildQuickStats(),
          const SizedBox(height: AppSpacing.cardGap),
          // Department Distribution
          ContentCard(
            height: 320,
            title: 'Department Distribution',
            child: DepartmentPieChart(data: DummyData.departmentDistribution),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return ContentCard(
      title: 'This Month',
      child: Column(
        children: [
          _QuickStatItem(
            icon: AppIcons.money,
            label: 'Salary Processed',
            value: '₹12.5L',
            color: AppColors.success,
          ),
          const Divider(height: 24),
          _QuickStatItem(
            icon: AppIcons.pf,
            label: 'PF Pending',
            value: '${DummyData.pfPending} employees',
            color: AppColors.warning,
          ),
          const Divider(height: 24),
          _QuickStatItem(
            icon: AppIcons.esic,
            label: 'ESIC Pending',
            value: '${DummyData.esicPending} employees',
            color: AppColors.error,
          ),
          const Divider(height: 24),
          _QuickStatItem(
            icon: AppIcons.attendance,
            label: 'Avg Attendance',
            value: '91.2%',
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(value, style: AppTypography.titleSmall),
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

  IconData get _icon {
    switch (type) {
      case 'add':
        return AppIcons.userAdd;
      case 'payment':
        return AppIcons.money;
      case 'document':
        return AppIcons.offerLetter;
      case 'approval':
        return AppIcons.approve;
      case 'upload':
        return AppIcons.upload;
      default:
        return AppIcons.info;
    }
  }

  Color get _color {
    switch (type) {
      case 'add':
        return AppColors.success;
      case 'payment':
        return AppColors.primary;
      case 'document':
        return AppColors.info;
      case 'approval':
        return AppColors.accent;
      case 'upload':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, size: 16, color: _color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Text(time, style: AppTypography.caption),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0);
  }
}

class _TaskItem extends StatefulWidget {
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

  @override
  State<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<_TaskItem> {
  bool _isHovered = false;

  Color get _priorityColor {
    switch (widget.priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.backgroundSecondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHovered ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTypography.labelLarge),
                  const SizedBox(height: 4),
                  Text(widget.description, style: AppTypography.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.dueDate,
                  style: AppTypography.labelSmall.copyWith(
                    color: widget.dueDate == 'Today'
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(
                  label: widget.priority.toUpperCase(),
                  type: widget.priority == 'high'
                      ? StatusType.error
                      : widget.priority == 'medium'
                      ? StatusType.warning
                      : StatusType.neutral,
                  isSmall: true,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05, end: 0);
  }
}
