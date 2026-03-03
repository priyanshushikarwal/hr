import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';
import '../../data/models/leave_request_model.dart';
import '../../domain/providers/leave_providers.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

/// Leave Approval Screen for HR Desktop
class LeaveApprovalScreen extends ConsumerStatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  ConsumerState<LeaveApprovalScreen> createState() =>
      _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends ConsumerState<LeaveApprovalScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveListProvider);
    final filteredRequests = _getFilteredRequests(leaveState.requests);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Leave Requests',
            subtitle: 'Review and manage employee leave applications',
            breadcrumbs: const ['Home', 'Leave Requests'],
            actions: [
              SecondaryButton(
                text: 'Refresh',
                icon: AppIcons.refresh,
                onPressed: () {
                  ref.read(leaveListProvider.notifier).loadLeaveRequests();
                },
              ),
            ],
          ),

          // Summary Cards
          _buildSummaryCards(leaveState),
          const SizedBox(height: AppSpacing.lg),

          // Filter Tabs
          _buildFilterTabs(leaveState),
          const SizedBox(height: AppSpacing.md),

          // Leave Request List
          if (leaveState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredRequests.isEmpty)
            _buildEmptyState()
          else
            ...filteredRequests.asMap().entries.map((entry) {
              return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LeaveRequestCard(
                      request: entry.value,
                      onApprove: () => _handleApprove(entry.value),
                      onReject: () => _handleReject(entry.value),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: entry.key * 80),
                    duration: 400.ms,
                  )
                  .slideY(begin: 0.1, end: 0);
            }),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(LeaveListState state) {
    final pending = state.requests
        .where((r) => r.status == LeaveStatus.pending)
        .length;
    final approved = state.requests
        .where((r) => r.status == LeaveStatus.approved)
        .length;
    final rejected = state.requests
        .where((r) => r.status == LeaveStatus.rejected)
        .length;

    return Row(
      children: [
        _SummaryCard(
          title: 'Total Requests',
          value: '${state.requests.length}',
          icon: AppIcons.documents,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Pending',
          value: '$pending',
          icon: AppIcons.pending,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Approved',
          value: '$approved',
          icon: AppIcons.approve,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Rejected',
          value: '$rejected',
          icon: AppIcons.reject,
          color: AppColors.error,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildFilterTabs(LeaveListState state) {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': state.requests.length},
      {
        'key': 'pending',
        'label': 'Pending',
        'count': state.requests
            .where((r) => r.status == LeaveStatus.pending)
            .length,
      },
      {
        'key': 'approved',
        'label': 'Approved',
        'count': state.requests
            .where((r) => r.status == LeaveStatus.approved)
            .length,
      },
      {
        'key': 'rejected',
        'label': 'Rejected',
        'count': state.requests
            .where((r) => r.status == LeaveStatus.rejected)
            .length,
      },
    ];

    return ContentCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: filters.map((filter) {
          final isActive = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () =>
                  setState(() => _selectedFilter = filter['key'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      filter['label'] as String,
                      style: AppTypography.labelLarge.copyWith(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filter['count']}',
                        style: AppTypography.labelSmall.copyWith(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ContentCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(AppIcons.documents, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'No leave requests found',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave requests from employees will appear here.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LeaveRequest> _getFilteredRequests(List<LeaveRequest> requests) {
    switch (_selectedFilter) {
      case 'pending':
        return requests.where((r) => r.status == LeaveStatus.pending).toList();
      case 'approved':
        return requests.where((r) => r.status == LeaveStatus.approved).toList();
      case 'rejected':
        return requests.where((r) => r.status == LeaveStatus.rejected).toList();
      default:
        return requests;
    }
  }

  Future<void> _handleApprove(LeaveRequest request) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Leave'),
        content: Text(
          'Approve ${request.employeeName ?? request.employeeId}\'s leave from '
          '${DateFormat('dd MMM yyyy').format(request.fromDate)} to '
          '${DateFormat('dd MMM yyyy').format(request.toDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(leaveListProvider.notifier)
          .approveLeave(request.id, user.userId);

      if (success && mounted) {
        // Create notification for the employee
        try {
          final notifRepo = NotificationRepository();
          await notifRepo.createNotification(
            userId: request.employeeId,
            title: 'Leave Approved',
            message:
                'Your leave request from ${DateFormat('dd MMM').format(request.fromDate)} to ${DateFormat('dd MMM').format(request.toDate)} has been approved.',
          );
        } catch (_) {
          // Notification failure shouldn't block the approval
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(LeaveRequest request) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${request.employeeName ?? request.employeeId}\'s leave request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter rejection reason...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(leaveListProvider.notifier)
          .rejectLeave(
            request.id,
            user.userId,
            reason: reasonController.text.trim().isNotEmpty
                ? reasonController.text.trim()
                : null,
          );

      if (success && mounted) {
        try {
          final notifRepo = NotificationRepository();
          await notifRepo.createNotification(
            userId: request.employeeId,
            title: 'Leave Rejected',
            message:
                'Your leave request from ${DateFormat('dd MMM').format(request.fromDate)} to ${DateFormat('dd MMM').format(request.toDate)} has been rejected.',
          );
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    reasonController.dispose();
  }
}

/// Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
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
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.titleLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Leave Request Card Widget
class _LeaveRequestCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _LeaveRequestCard({
    required this.request,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          // Employee Info
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (request.employeeName ?? 'E')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      request.employeeName ?? request.employeeId,
                      style: AppTypography.titleSmall,
                    ),
                    if (request.employeeCode != null) ...[
                      const SizedBox(width: 8),
                      TextBadge(
                        label: request.employeeCode!,
                        backgroundColor: AppColors.backgroundSecondary,
                        textColor: AppColors.textSecondary,
                        isSmall: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      AppIcons.calendar,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(request.fromDate)} → ${DateFormat('dd MMM yyyy').format(request.toDate)}',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${request.totalDays} day${request.totalDays > 1 ? 's' : ''}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.infoDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Reason: ${request.reason}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status / Actions
          if (request.isPending)
            Row(
              children: [
                _ActionButton(
                  icon: AppIcons.approve,
                  label: 'Approve',
                  color: AppColors.success,
                  onTap: onApprove,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: AppIcons.reject,
                  label: 'Reject',
                  color: AppColors.error,
                  onTap: onReject,
                ),
              ],
            )
          else
            StatusBadge(
              label: request.status.value.toUpperCase(),
              type: request.isApproved ? StatusType.success : StatusType.error,
            ),
        ],
      ),
    );
  }
}

/// Small Action Button
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: AppSpacing.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withOpacity(0.15)
                : widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.color.withOpacity(_isHovered ? 0.4 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
