import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';
import '../../data/models/offer_letter_model.dart';
import '../../domain/providers/offer_letter_providers.dart';
import '../widgets/create_offer_letter_dialog.dart';
import '../widgets/preview_offer_letter_dialog.dart';
import '../utils/offer_letter_pdf_generator.dart';

/// Offer Letter Screen — Create and manage offer letters
class OfferLetterScreen extends ConsumerStatefulWidget {
  const OfferLetterScreen({super.key});

  @override
  ConsumerState<OfferLetterScreen> createState() => _OfferLetterScreenState();
}

class _OfferLetterScreenState extends ConsumerState<OfferLetterScreen> {
  String _currentTab = 'all';

  List<OfferLetter> _getFiltered(List<OfferLetter> letters) {
    if (_currentTab == 'all') return letters;
    return letters.where((l) => l.status == _currentTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offerLetterProvider);
    final allLetters = state.letters;
    final filteredLetters = _getFiltered(allLetters);

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
              PrimaryButton(
                text: 'Create Offer Letter',
                icon: AppIcons.add,
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const CreateOfferLetterDialog(),
                  );
                  if (result == true) {
                    ref.read(offerLetterProvider.notifier).loadOfferLetters();
                  }
                },
              ),
            ],
          ),

          // Stats Cards
          _buildStatsCards(allLetters),

          const SizedBox(height: AppSpacing.lg),

          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else
            // Offer Letters List
            ContentCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Tab Bar
                  _buildTabBar(allLetters),

                  // List
                  ...List.generate(filteredLetters.length, (index) {
                    return _OfferLetterCard(
                      offerLetter: filteredLetters[index],
                      onView: () => _showPreview(filteredLetters[index]),
                      onEdit: () => _showEdit(filteredLetters[index]),
                      onDownload: () => _downloadPdf(filteredLetters[index]),
                    );
                  }),

                  if (filteredLetters.isEmpty)
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
                              allLetters.isEmpty
                                  ? 'No offer letters yet. Click "Create Offer Letter" to get started.'
                                  : 'No offer letters found for this filter.',
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

  void _showPreview(OfferLetter letter) {
    showDialog(
      context: context,
      builder: (context) => PreviewOfferLetterDialog(letter: letter),
    );
  }

  void _showEdit(OfferLetter letter) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateOfferLetterDialog(existingLetter: letter),
    );
    if (result == true) {
      ref.read(offerLetterProvider.notifier).loadOfferLetters();
    }
  }

  void _downloadPdf(OfferLetter letter) {
    OfferLetterPdfGenerator.printPreview(letter);
  }

  Widget _buildStatsCards(List<OfferLetter> offerLetters) {
    final total = offerLetters.length;
    final draft = offerLetters.where((l) => l.isDraft).length;
    final sent = offerLetters.where((l) => l.isSent).length;
    final accepted = offerLetters.where((l) => l.isAccepted).length;
    final rejected = offerLetters.where((l) => l.isRejected).length;

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
          label: 'Draft',
          value: draft.toString(),
          icon: AppIcons.edit,
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

  Widget _buildTabBar(List<OfferLetter> allLetters) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'All',
            count: allLetters.length,
            isActive: _currentTab == 'all',
            onTap: () => setState(() => _currentTab = 'all'),
          ),
          _TabButton(
            label: 'Draft',
            count: allLetters.where((l) => l.isDraft).length,
            isActive: _currentTab == 'draft',
            onTap: () => setState(() => _currentTab = 'draft'),
          ),
          _TabButton(
            label: 'Approved',
            count: allLetters.where((l) => l.isApproved).length,
            isActive: _currentTab == 'approved',
            onTap: () => setState(() => _currentTab = 'approved'),
          ),
          _TabButton(
            label: 'Sent',
            count: allLetters.where((l) => l.isSent).length,
            isActive: _currentTab == 'sent',
            onTap: () => setState(() => _currentTab = 'sent'),
          ),
          _TabButton(
            label: 'Accepted',
            count: allLetters.where((l) => l.isAccepted).length,
            isActive: _currentTab == 'accepted',
            onTap: () => setState(() => _currentTab = 'accepted'),
          ),
          const Spacer(),
          AppSearchField(hint: 'Search by name...', width: 250),
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
  final OfferLetter offerLetter;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDownload;

  const _OfferLetterCard({
    required this.offerLetter,
    required this.onView,
    required this.onEdit,
    required this.onDownload,
  });

  @override
  State<_OfferLetterCard> createState() => _OfferLetterCardState();
}

class _OfferLetterCardState extends State<_OfferLetterCard> {
  bool _isHovered = false;

  StatusType get _statusType {
    switch (widget.offerLetter.status) {
      case 'draft':
        return StatusType.neutral;
      case 'approved':
        return StatusType.info;
      case 'sent':
        return StatusType.warning;
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
      case 'approved':
        return 'Approved';
      case 'sent':
        return 'Sent';
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
            // Employee Info
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  UserAvatar(name: widget.offerLetter.employeeName, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.offerLetter.employeeName,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.offerLetter.employeeCode,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
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
                    widget.offerLetter.designation,
                    style: AppTypography.labelLarge,
                    overflow: TextOverflow.ellipsis,
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
                '₹${widget.offerLetter.ctc.toInt()}/mo',
                style: AppTypography.labelLarge,
              ),
            ),

            // Joining Date
            Expanded(
              child: Text(
                DateFormat(
                  'dd MMM yyyy',
                ).format(widget.offerLetter.joiningDate),
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
                    onPressed: widget.onView,
                  ),
                  AppIconButton(
                    icon: AppIcons.edit,
                    tooltip: 'Edit',
                    onPressed: widget.onEdit,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      AppIcons.moreVertical,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (value) {
                      if (value == 'download') {
                        widget.onDownload();
                      }
                    },
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
}
