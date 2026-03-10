import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// Custom Text Field with premium styling
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final bool isRequired;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onSuffixTap,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode,
    this.isRequired = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _isObscured = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(widget.label!, style: AppTypography.formLabel),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: AppTypography.formLabel.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnimatedContainer(
          duration: AppSpacing.durationFast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color:
                          (widget.errorText != null
                                  ? AppColors.error
                                  : AppColors.primary)
                              .withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText ? _isObscured : false,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            autovalidateMode: widget.autovalidateMode,
            style: AppTypography.formInput,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              helperText: widget.helperText,
              filled: true,
              fillColor: widget.enabled
                  ? AppColors.cardBackground
                  : AppColors.backgroundSecondary,
              prefixIcon:
                  widget.prefix ??
                  (widget.prefixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            widget.prefixIcon,
                            size: 20,
                            color: _isFocused
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        )
                      : null),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: widget.suffix ?? _buildSuffixIcon(),
              suffixIconConstraints: const BoxConstraints(minWidth: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: Icon(
            _isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: AppColors.textTertiary,
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 14),
        child: GestureDetector(
          onTap: widget.onSuffixTap,
          child: Icon(
            widget.suffixIcon,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return null;
  }
}

/// Search Text Field
class AppSearchField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double? width;

  const AppSearchField({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 280,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.formInput,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: controller?.text.isNotEmpty == true
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      controller?.clear();
                      onClear?.call();
                    },
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }
}

/// Dropdown Field
class AppDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? errorText;
  final IconData? prefixIcon;

  const AppDropdownField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    required this.itemLabel,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.errorText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(label!, style: AppTypography.formLabel),
              if (isRequired)
                Text(
                  ' *',
                  style: AppTypography.formLabel.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: hint != null
              ? Text(hint!, style: AppTypography.formHint)
              : null,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), style: AppTypography.formInput),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          style: AppTypography.formInput,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
          ),
          dropdownColor: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
          decoration: InputDecoration(
            errorText: errorText,
            filled: true,
            fillColor: enabled
                ? AppColors.cardBackground
                : AppColors.backgroundSecondary,
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      prefixIcon,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),
      ],
    );
  }
}

/// Date Picker Field
class AppDateField extends StatelessWidget {
  final String? label;
  final String? hint;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? errorText;

  const AppDateField({
    super.key,
    this.label,
    this.hint = 'Select date',
    this.value,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value != null
        ? '${value!.day.toString().padLeft(2, '0')} ${_monthName(value!.month)} ${value!.year}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(label!, style: AppTypography.formLabel),
              if (isRequired)
                Text(
                  ' *',
                  style: AppTypography.formLabel.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        InkWell(
          onTap: enabled
              ? () async {
                  final now = DateTime.now();
                  DateTime initial = value ?? now;
                  if (lastDate != null && initial.isAfter(lastDate!)) {
                    initial = lastDate!;
                  }
                  if (firstDate != null && initial.isBefore(firstDate!)) {
                    initial = firstDate!;
                  }
                  final date = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: firstDate ?? DateTime(1950),
                    lastDate: lastDate ?? DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: AppColors.textOnPrimary,
                            surface: AppColors.cardBackground,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    onChanged?.call(date);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
          child: Container(
            height: AppSpacing.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.cardBackground
                  : AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
              border: Border.all(
                color: errorText != null ? AppColors.error : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayValue ?? hint ?? '',
                    style: displayValue != null
                        ? AppTypography.formInput
                        : AppTypography.formHint,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }
}
