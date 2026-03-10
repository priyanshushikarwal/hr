import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../data/models/visit_model.dart';
import '../../domain/providers/visit_providers.dart';

/// Visit Detail Dialog — Shows selfie, location, and visit info
class VisitDetailDialog extends ConsumerWidget {
  final VisitRecord visit;

  const VisitDetailDialog({super.key, required this.visit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(visitListProvider.notifier);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selfie Section
                    _buildSelfieSection(notifier),
                    const SizedBox(height: 24),

                    // Location Section
                    _buildLocationSection(),
                    const SizedBox(height: 24),

                    // Visit Details
                    _buildVisitDetails(),
                    const SizedBox(height: 24),

                    // Status & Approval
                    _buildStatusSection(),

                    // Rejection Reason
                    if (visit.isRejected &&
                        visit.rejectionReason != null &&
                        visit.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildRejectionReason(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            if (visit.isPending) _buildFooterActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(AppIcons.location, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Visit Details', style: AppTypography.titleMedium),
                Text(
                  '${visit.employeeName ?? visit.employeeId} • ${DateFormat('dd MMM yyyy').format(visit.visitDate)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(AppIcons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieSection(VisitListNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.fileImage, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Visit Selfie',
                style: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (visit.hasSelfie)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder<dynamic>(
              future: notifier.getSelfieBytes(visit.selfieFileId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: double.infinity,
                    height: 350,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.fileImage,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load selfie',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.fileImage,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text(
                  'No selfie uploaded',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        if (visit.selfieTimestamp != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(AppIcons.clock, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Taken at: ${DateFormat('dd MMM yyyy, hh:mm:ss a').format(visit.selfieTimestamp!)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: visit.hasLocation
            ? AppColors.success.withOpacity(0.05)
            : AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: visit.hasLocation
              ? AppColors.success.withOpacity(0.2)
              : AppColors.warning.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.location,
                size: 18,
                color: visit.hasLocation ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Location Verification',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: visit.hasLocation
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
              const Spacer(),
              if (visit.hasLocation)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.verified,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Location Captured',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.warning,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'No Location',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (visit.hasLocation) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Coordinates',
              '${visit.latitude!.toStringAsFixed(6)}, ${visit.longitude!.toStringAsFixed(6)}',
            ),
            if (visit.locationAddress != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow('Address', visit.locationAddress!),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInMaps(visit.latitude!, visit.longitude!),
                icon: const Icon(AppIcons.location, size: 16),
                label: const Text('Open in Google Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Location was not captured for this visit.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.documents, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Visit Information',
                style: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Employee', visit.employeeName ?? visit.employeeId),
              if (visit.employeeCode != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Employee Code', visit.employeeCode!),
              ],
              const SizedBox(height: 8),
              _buildInfoRow('Purpose', visit.purpose),
              if (visit.clientName != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Client/Company', visit.clientName!),
              ],
              if (visit.visitAddress != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Visit Address', visit.visitAddress!),
              ],
              const SizedBox(height: 8),
              _buildInfoRow(
                'Visit Date',
                DateFormat('dd MMM yyyy, hh:mm a').format(visit.visitDate),
              ),
              if (visit.remarks != null && visit.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Remarks', visit.remarks!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Status', visit.status.value.toUpperCase()),
          if (visit.approvedBy != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Reviewed By', visit.approvedBy!),
          ],
          if (visit.approvedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Reviewed At',
              DateFormat('dd MMM yyyy, hh:mm a').format(visit.approvedAt!),
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            'Submitted',
            DateFormat('dd MMM yyyy, hh:mm a').format(visit.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReason() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.info, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejection Reason',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  visit.rejectionReason!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SecondaryButton(
            text: 'Reject',
            icon: AppIcons.reject,
            onPressed: () {
              Navigator.pop(context);
              // Let the parent screen handle rejection
            },
          ),
          const SizedBox(width: 12),
          PrimaryButton(
            text: 'Approve Visit',
            icon: AppIcons.approve,
            onPressed: () {
              Navigator.pop(context);
              // Let the parent screen handle approval
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  void _openInMaps(double lat, double lng) {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
