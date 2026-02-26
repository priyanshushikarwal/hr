import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';

/// Primary Button with gradient and hover effects
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double? width;
  final double height;
  final bool useGradient;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.useGradient = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        width: widget.isExpanded ? double.infinity : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.useGradient ? AppColors.primaryGradient : null,
          color: widget.useGradient
              ? null
              : (widget.onPressed == null
                    ? AppColors.textDisabled
                    : (_isHovered ? AppColors.primaryDark : AppColors.primary)),
          borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
          boxShadow: _isHovered && widget.onPressed != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.buttonPaddingHorizontal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: widget.isExpanded
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ] else ...[
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: AppSpacing.buttonIconSize,
                        color: AppColors.textOnPrimary,
                      ),
                      const SizedBox(width: AppSpacing.buttonGap),
                    ],
                    Text(widget.text, style: AppTypography.button),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary/Outlined Button
class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double? width;
  final double height;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.color,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        width: widget.isExpanded ? double.infinity : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _isHovered
              ? buttonColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
          border: Border.all(
            color: widget.onPressed == null
                ? AppColors.textDisabled
                : buttonColor,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.buttonPaddingHorizontal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: widget.isExpanded
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                      ),
                    ),
                  ] else ...[
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: AppSpacing.buttonIconSize,
                        color: buttonColor,
                      ),
                      const SizedBox(width: AppSpacing.buttonGap),
                    ],
                    Text(
                      widget.text,
                      style: AppTypography.button.copyWith(color: buttonColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text/Ghost Button
class GhostButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double? iconSize;

  const GhostButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
    this.iconSize,
  });

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        decoration: BoxDecoration(
          color: _isHovered
              ? buttonColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: widget.iconSize ?? 18,
                      color: buttonColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.text,
                    style: AppTypography.labelLarge.copyWith(
                      color: buttonColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon Button with tooltip and hover state
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppColors.textSecondary;
    final bgColor = widget.backgroundColor ?? Colors.transparent;

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isHovered
              ? (bgColor == Colors.transparent
                    ? AppColors.backgroundSecondary
                    : bgColor.withOpacity(0.8))
              : bgColor,
          borderRadius: BorderRadius.circular(widget.size / 4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(widget.size / 4),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: _isHovered ? AppColors.primary : iconColor,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

/// Floating Action Button
class AppFloatingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool isExtended;

  const AppFloatingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.isExtended = false,
  });

  @override
  State<AppFloatingButton> createState() => _AppFloatingButtonState();
}

class _AppFloatingButtonState extends State<AppFloatingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(widget.isExtended ? 16 : 56),
          elevation: _isHovered ? 8 : 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(widget.isExtended ? 16 : 56),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isExtended ? 20 : 16,
                vertical: 16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: AppColors.textOnPrimary, size: 24),
                  if (widget.isExtended && widget.label != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(widget.label!, style: AppTypography.button),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 300.ms,
      curve: Curves.easeOutBack,
    );
  }
}
