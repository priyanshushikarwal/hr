import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Status Badge/Chip for displaying status
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 6 : 8,
            height: isSmall ? 6 : 8,
            decoration: BoxDecoration(
              color: colors.dot,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            label,
            style: (isSmall ? AppTypography.labelSmall : AppTypography.chip)
                .copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }

  _StatusColors _getColors(StatusType type) {
    switch (type) {
      case StatusType.success:
        return _StatusColors(
          background: AppColors.successSurface,
          text: AppColors.successDark,
          dot: AppColors.success,
        );
      case StatusType.warning:
        return _StatusColors(
          background: AppColors.warningSurface,
          text: AppColors.warningDark,
          dot: AppColors.warning,
        );
      case StatusType.error:
        return _StatusColors(
          background: AppColors.errorSurface,
          text: AppColors.errorDark,
          dot: AppColors.error,
        );
      case StatusType.info:
        return _StatusColors(
          background: AppColors.infoSurface,
          text: AppColors.infoDark,
          dot: AppColors.info,
        );
      case StatusType.neutral:
        return _StatusColors(
          background: AppColors.backgroundSecondary,
          text: AppColors.textSecondary,
          dot: AppColors.textTertiary,
        );
      case StatusType.primary:
        return _StatusColors(
          background: AppColors.primarySurface,
          text: AppColors.primaryDark,
          dot: AppColors.primary,
        );
    }
  }
}

enum StatusType { success, warning, error, info, neutral, primary }

class _StatusColors {
  final Color background;
  final Color text;
  final Color dot;

  _StatusColors({
    required this.background,
    required this.text,
    required this.dot,
  });
}

/// Simple text badge without dot
class TextBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSmall;

  const TextBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 10,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primarySurface,
        borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
      ),
      child: Text(
        label,
        style: (isSmall ? AppTypography.labelSmall : AppTypography.chip)
            .copyWith(color: textColor ?? AppColors.primaryDark),
      ),
    );
  }
}

/// Count Badge (for notifications, etc.)
class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final bool showZero;
  final double size;

  const CountBadge({
    super.key,
    required this.count,
    this.color,
    this.showZero = false,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return const SizedBox.shrink();
    }

    final displayCount = count > 99 ? '99+' : count.toString();
    final badgeColor = color ?? AppColors.error;

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textOnPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Employee Type Badge
class EmployeeTypeBadge extends StatelessWidget {
  final String type; // 'office' or 'factory'
  final bool isSmall;

  const EmployeeTypeBadge({
    super.key,
    required this.type,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOffice = type.toLowerCase() == 'office';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isOffice ? AppColors.secondarySurface : AppColors.accentSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffice ? Icons.business_rounded : Icons.factory_rounded,
            size: isSmall ? 12 : 14,
            color: isOffice ? AppColors.secondaryDark : AppColors.accentDark,
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            isOffice ? 'Office' : 'Factory',
            style: (isSmall ? AppTypography.labelSmall : AppTypography.chip)
                .copyWith(
                  color: isOffice
                      ? AppColors.secondaryDark
                      : AppColors.accentDark,
                ),
          ),
        ],
      ),
    );
  }
}

/// Approval Status Badge
class ApprovalBadge extends StatelessWidget {
  final String status; // 'draft', 'pending', 'approved', 'rejected', 'sent'
  final bool isSmall;

  const ApprovalBadge({super.key, required this.status, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    late StatusType type;
    late String label;

    switch (status.toLowerCase()) {
      case 'draft':
        type = StatusType.neutral;
        label = 'Draft';
        break;
      case 'pending':
        type = StatusType.warning;
        label = 'Pending';
        break;
      case 'approved':
        type = StatusType.success;
        label = 'Approved';
        break;
      case 'rejected':
        type = StatusType.error;
        label = 'Rejected';
        break;
      case 'sent':
        type = StatusType.info;
        label = 'Sent';
        break;
      default:
        type = StatusType.neutral;
        label = status;
    }

    return StatusBadge(label: label, type: type, isSmall: isSmall);
  }
}
