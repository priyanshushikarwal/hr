import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';

/// Offer Letter Screen - Create and manage offer letters
class OfferLetterScreen extends StatefulWidget {
  const OfferLetterScreen({super.key});

  @override
  State<OfferLetterScreen> createState() => _OfferLetterScreenState();
}

class _OfferLetterScreenState extends State<OfferLetterScreen> {
  String _currentTab = 'all';

  final List<_OfferLetter> _offerLetters = [
    _OfferLetter(
      id: 'OL-2024-001',
      candidateName: 'Ravi Teja',
      position: 'Software Developer',
      department: 'Engineering',
      ctc: 850000,
      joiningDate: DateTime(2024, 2, 1),
      status: 'pending',
      createdDate: DateTime(2024, 1, 20),
    ),
    _OfferLetter(
      id: 'OL-2024-002',
      candidateName: 'Meera Krishnan',
      position: 'HR Executive',
      department: 'Human Resources',
      ctc: 450000,
      joiningDate: DateTime(2024, 2, 15),
      status: 'sent',
      createdDate: DateTime(2024, 1, 18),
    ),
    _OfferLetter(
      id: 'OL-2024-003',
      candidateName: 'Arjun Reddy',
      position: 'Production Operator',
      department: 'Production',
      ctc: 350000,
      joiningDate: DateTime(2024, 1, 25),
      status: 'accepted',
      createdDate: DateTime(2024, 1, 10),
    ),
    _OfferLetter(
      id: 'OL-2024-004',
      candidateName: 'Sanya Malik',
      position: 'Accounts Executive',
      department: 'Finance',
      ctc: 500000,
      joiningDate: DateTime(2024, 3, 1),
      status: 'draft',
      createdDate: DateTime(2024, 1, 22),
    ),
    _OfferLetter(
      id: 'OL-2023-025',
      candidateName: 'Karan Singh',
      position: 'Sales Executive',
      department: 'Sales',
      ctc: 400000,
      joiningDate: DateTime(2023, 12, 15),
      status: 'rejected',
      createdDate: DateTime(2023, 12, 1),
    ),
  ];

  List<_OfferLetter> get _filteredLetters {
    if (_currentTab == 'all') return _offerLetters;
    return _offerLetters.where((l) => l.status == _currentTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Offer Letters',
            subtitle: 'Create and manage offer letters for new hires',
            breadcrumbs: const ['Home', 'Offer Letters'],
            actions: [
              SecondaryButton(
                text: 'Templates',
                icon: AppIcons.template,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: 'Create Offer Letter',
                icon: AppIcons.add,
                onPressed: () {},
              ),
            ],
          ),

          // Stats Cards
          _buildStatsCards(),

          const SizedBox(height: AppSpacing.lg),

          // Offer Letters List
          ContentCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Tab Bar
                _buildTabBar(),

                // List
                ...List.generate(_filteredLetters.length, (index) {
                  return _OfferLetterCard(offerLetter: _filteredLetters[index]);
                }),

                if (_filteredLetters.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            AppIcons.offerLetter,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No offer letters found',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final total = _offerLetters.length;
    final pending = _offerLetters.where((l) => l.status == 'pending').length;
    final sent = _offerLetters.where((l) => l.status == 'sent').length;
    final accepted = _offerLetters.where((l) => l.status == 'accepted').length;
    final rejected = _offerLetters.where((l) => l.status == 'rejected').length;

    return Row(
      children: [
        _StatCard(
          label: 'Total',
          value: total.toString(),
          icon: AppIcons.offerLetter,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _StatCard(
          label: 'Pending Approval',
          value: pending.toString(),
          icon: AppIcons.pending,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.md),
        _StatCard(
          label: 'Sent',
          value: sent.toString(),
          icon: AppIcons.send,
          color: AppColors.info,
        ),
        const SizedBox(width: AppSpacing.md),
        _StatCard(
          label: 'Accepted',
          value: accepted.toString(),
          icon: AppIcons.check,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _StatCard(
          label: 'Rejected',
          value: rejected.toString(),
          icon: AppIcons.xCircle,
          color: AppColors.error,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'All',
            count: _offerLetters.length,
            isActive: _currentTab == 'all',
            onTap: () => setState(() => _currentTab = 'all'),
          ),
          _TabButton(
            label: 'Draft',
            count: _offerLetters.where((l) => l.status == 'draft').length,
            isActive: _currentTab == 'draft',
            onTap: () => setState(() => _currentTab = 'draft'),
          ),
          _TabButton(
            label: 'Pending',
            count: _offerLetters.where((l) => l.status == 'pending').length,
            isActive: _currentTab == 'pending',
            onTap: () => setState(() => _currentTab = 'pending'),
          ),
          _TabButton(
            label: 'Sent',
            count: _offerLetters.where((l) => l.status == 'sent').length,
            isActive: _currentTab == 'sent',
            onTap: () => setState(() => _currentTab = 'sent'),
          ),
          _TabButton(
            label: 'Accepted',
            count: _offerLetters.where((l) => l.status == 'accepted').length,
            isActive: _currentTab == 'accepted',
            onTap: () => setState(() => _currentTab = 'accepted'),
          ),
          const Spacer(),
          AppSearchField(hint: 'Search by candidate name...', width: 250),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.titleLarge),
                Text(label, style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: AppSpacing.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primarySurface
                : (_isHovered
                      ? AppColors.backgroundSecondary
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isActive ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.count.toString(),
                  style: AppTypography.labelSmall.copyWith(
                    color: widget.isActive
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferLetterCard extends StatefulWidget {
  final _OfferLetter offerLetter;

  const _OfferLetterCard({required this.offerLetter});

  @override
  State<_OfferLetterCard> createState() => _OfferLetterCardState();
}

class _OfferLetterCardState extends State<_OfferLetterCard> {
  bool _isHovered = false;

  StatusType get _statusType {
    switch (widget.offerLetter.status) {
      case 'draft':
        return StatusType.neutral;
      case 'pending':
        return StatusType.warning;
      case 'sent':
        return StatusType.info;
      case 'accepted':
        return StatusType.success;
      case 'rejected':
        return StatusType.error;
      default:
        return StatusType.neutral;
    }
  }

  String get _statusLabel {
    switch (widget.offerLetter.status) {
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending Approval';
      case 'sent':
        return 'Sent to Candidate';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return widget.offerLetter.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.backgroundSecondary
              : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // Candidate Info
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  UserAvatar(name: widget.offerLetter.candidateName, size: 44),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.offerLetter.candidateName,
                        style: AppTypography.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(widget.offerLetter.id, style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),

            // Position
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.offerLetter.position,
                    style: AppTypography.labelLarge,
                  ),
                  Text(
                    widget.offerLetter.department,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            // CTC
            Expanded(
              child: Text(
                '₹${(widget.offerLetter.ctc / 100000).toStringAsFixed(1)} LPA',
                style: AppTypography.labelLarge,
              ),
            ),

            // Joining Date
            Expanded(
              child: Text(
                _formatDate(widget.offerLetter.joiningDate),
                style: AppTypography.tableCell,
              ),
            ),

            // Status
            Expanded(
              child: StatusBadge(label: _statusLabel, type: _statusType),
            ),

            // Actions
            SizedBox(
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppIconButton(
                    icon: AppIcons.view,
                    tooltip: 'Preview',
                    onPressed: () {},
                  ),
                  AppIconButton(
                    icon: AppIcons.edit,
                    tooltip: 'Edit',
                    onPressed: () {},
                  ),
                  if (widget.offerLetter.status == 'draft' ||
                      widget.offerLetter.status == 'pending')
                    AppIconButton(
                      icon: AppIcons.send,
                      tooltip: 'Send',
                      color: AppColors.primary,
                      onPressed: () {},
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      AppIcons.moreVertical,
                      color: AppColors.textSecondary,
                    ),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(AppIcons.download, size: 18),
                            const SizedBox(width: 8),
                            const Text('Download PDF'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(AppIcons.copy, size: 18),
                            const SizedBox(width: 8),
                            const Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.delete,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _OfferLetter {
  final String id;
  final String candidateName;
  final String position;
  final String department;
  final double ctc;
  final DateTime joiningDate;
  final String status;
  final DateTime createdDate;

  const _OfferLetter({
    required this.id,
    required this.candidateName,
    required this.position,
    required this.department,
    required this.ctc,
    required this.joiningDate,
    required this.status,
    required this.createdDate,
  });
}
