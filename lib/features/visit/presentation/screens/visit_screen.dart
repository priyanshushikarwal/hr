import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';
import '../../data/models/visit_model.dart';
import '../../domain/providers/visit_providers.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../widgets/visit_detail_dialog.dart';

/// Visit Tracking Screen for HR Desktop
class VisitScreen extends ConsumerStatefulWidget {
  const VisitScreen({super.key});

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final visitState = ref.watch(visitListProvider);
    final filteredVisits = _getFilteredVisits(visitState.visits);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Employee Visits',
            subtitle: 'Track and verify employee visit selfies & locations',
            breadcrumbs: const ['Home', 'Visits'],
            actions: [
              SecondaryButton(
                text: 'Refresh',
                icon: AppIcons.refresh,
                onPressed: () {
                  ref.read(visitListProvider.notifier).loadVisits();
                },
              ),
            ],
          ),

          // Summary Cards
          _buildSummaryCards(visitState),
          const SizedBox(height: AppSpacing.lg),

          // Filter Tabs
          _buildFilterTabs(visitState),
          const SizedBox(height: AppSpacing.md),

          // Visit List
          if (visitState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (visitState.error != null)
            _buildErrorState(visitState.error!)
          else if (filteredVisits.isEmpty)
            _buildEmptyState()
          else
            ...filteredVisits.asMap().entries.map((entry) {
              return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VisitCard(
                      visit: entry.value,
                      onTap: () => _showVisitDetail(entry.value),
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

  Widget _buildSummaryCards(VisitListState state) {
    return Row(
      children: [
        _SummaryCard(
          title: 'Total Visits',
          value: '${state.visits.length}',
          icon: AppIcons.location,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Pending',
          value: '${state.pendingCount}',
          icon: AppIcons.pending,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Approved',
          value: '${state.approvedCount}',
          icon: AppIcons.approve,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          title: 'Rejected',
          value: '${state.rejectedCount}',
          icon: AppIcons.reject,
          color: AppColors.error,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildFilterTabs(VisitListState state) {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': state.visits.length},
      {'key': 'pending', 'label': 'Pending', 'count': state.pendingCount},
      {'key': 'approved', 'label': 'Approved', 'count': state.approvedCount},
      {'key': 'rejected', 'label': 'Rejected', 'count': state.rejectedCount},
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
                  color:
                      isActive ? AppColors.primarySurface : Colors.transparent,
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
              Icon(AppIcons.location, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'No visits found',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When employees submit visit selfies, they will appear here for verification.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ContentCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(AppIcons.error, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(error, style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              SecondaryButton(
                text: 'Retry',
                icon: AppIcons.refresh,
                onPressed: () {
                  ref.read(visitListProvider.notifier).loadVisits();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<VisitRecord> _getFilteredVisits(List<VisitRecord> visits) {
    switch (_selectedFilter) {
      case 'pending':
        return visits.where((v) => v.isPending).toList();
      case 'approved':
        return visits.where((v) => v.isApproved).toList();
      case 'rejected':
        return visits.where((v) => v.isRejected).toList();
      default:
        return visits;
    }
  }

  void _showVisitDetail(VisitRecord visit) {
    showDialog(
      context: context,
      builder: (context) => VisitDetailDialog(visit: visit),
    );
  }

  Future<void> _handleApprove(VisitRecord visit) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Visit'),
        content: Text(
          'Approve ${visit.employeeName ?? visit.employeeId}\'s visit to '
          '${visit.clientName ?? visit.purpose} on '
          '${DateFormat('dd MMM yyyy').format(visit.visitDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(visitListProvider.notifier)
            .approve(visit.id, user.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit approved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject(VisitRecord visit) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${visit.employeeName ?? visit.employeeId}\'s visit?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
            child:
                const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(visitListProvider.notifier).reject(
              visit.id,
              user.userId,
              reason: reasonController.text.isNotEmpty
                  ? reasonController.text
                  : null,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit rejected'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}

// ==================== VISIT CARD ====================

class _VisitCard extends ConsumerWidget {
  final VisitRecord visit;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VisitCard({
    required this.visit,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(visitListProvider.notifier);

    return ContentCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selfie Thumbnail
              _buildSelfieThumbnail(notifier),

              const SizedBox(width: AppSpacing.md),

              // Visit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visit.employeeName ?? visit.employeeId,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildStatusBadge(),
                      ],
                    ),
                    if (visit.employeeCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        visit.employeeCode!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Purpose
                    Row(
                      children: [
                        Icon(AppIcons.briefcase,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            visit.purpose,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Client/Location
                    if (visit.clientName != null)
                      Row(
                        children: [
                          Icon(AppIcons.user,
                              size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            visit.clientName!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    // Date & Location
                    Row(
                      children: [
                        Icon(AppIcons.calendar,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(visit.visitDate),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (visit.hasLocation) ...[
                          const SizedBox(width: 16),
                          Icon(AppIcons.location,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              visit.locationAddress ??
                                  '${visit.latitude!.toStringAsFixed(4)}, ${visit.longitude!.toStringAsFixed(4)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.success,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Actions
              if (visit.isPending)
                Column(
                  children: [
                    IconButton(
                      onPressed: onApprove,
                      icon: const Icon(AppIcons.approve),
                      color: AppColors.success,
                      tooltip: 'Approve',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.success.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: onReject,
                      icon: const Icon(AppIcons.reject),
                      color: AppColors.error,
                      tooltip: 'Reject',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.1),
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(AppIcons.view),
                  color: AppColors.textSecondary,
                  tooltip: 'View Details',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelfieThumbnail(VisitListNotifier notifier) {
    if (!visit.hasSelfie) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          AppIcons.user,
          size: 32,
          color: AppColors.textTertiary,
        ),
      );
    }

    final selfieFuture = notifier.getSelfiePreviewBytes(visit.selfieFileId!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<dynamic>(
        future: selfieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                AppIcons.fileImage,
                size: 32,
                color: AppColors.textTertiary,
              ),
            );
          }
          return Image.memory(
            snapshot.data!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    switch (visit.status) {
      case VisitStatus.approved:
        color = AppColors.success;
        label = 'Approved';
        break;
      case VisitStatus.rejected:
        color = AppColors.error;
        label = 'Rejected';
        break;
      case VisitStatus.pending:
        color = AppColors.warning;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==================== SUMMARY CARD ====================

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
      child: ContentCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
