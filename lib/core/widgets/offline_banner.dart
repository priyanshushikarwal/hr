import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';
import '../theme/theme.dart';

/// Shows a banner when the app is offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);

    if (status == NetworkStatus.online) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.15),
        border: Border(
          bottom: BorderSide(color: AppColors.warning.withOpacity(0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(
            'Offline Mode — Changes are saved locally and will sync when connection is restored',
            style: AppTypography.labelMedium.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}
