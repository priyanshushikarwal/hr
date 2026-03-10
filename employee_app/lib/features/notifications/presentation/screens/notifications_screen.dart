import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (state.items.where((n) => !n.isRead).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                backgroundColor: AppColors.errorSurface,
                side: BorderSide.none,
                label: Text(
                  '${state.items.where((n) => !n.isRead).length} New',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorDark,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationProvider.notifier).load(),
        color: AppColors.primary,
        child: _buildBody(state, ref),
      ),
    );
  }

  Widget _buildBody(NotificationState state, WidgetRef ref) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 400,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              const Text(
                'All Caught Up!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No new notifications right now.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notif = state.items[index];
        final dt = DateTime.tryParse(notif.createdAt);

        return InkWell(
          onTap: () {
            if (!notif.isRead) {
              ref.read(notificationProvider.notifier).markAsRead(notif.id);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child:
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? AppColors.cardBackground
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notif.isRead
                            ? AppColors.borderLight
                            : AppColors.primaryLight,
                      ),
                      boxShadow: notif.isRead
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? AppColors.backgroundSecondary
                                : AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(notif.type),
                            size: 20,
                            color: notif.isRead
                                ? AppColors.textTertiary
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notif.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: notif.isRead
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dt != null
                                    ? DateFormat('dd MMM, hh:mm a').format(dt)
                                    : '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (50 * index).ms)
                  .slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'leave_approved':
        return Icons.check_circle_outline;
      case 'leave_rejected':
        return Icons.cancel_outlined;
      case 'attendance_marked':
        return Icons.access_time_rounded;
      case 'salary_processed':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
