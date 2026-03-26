import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';

/// A reusable, brand-consistent text field component.
///
/// Supports labels, hint text, prefix/suffix icons, validation with
/// error display, password toggle, multiline mode, and an optional
/// character counter.
///
/// ```dart
/// AppTextField(
///   label: 'Email',
///   hint: 'you@example.com',
///   prefixIcon: Icons.email_outlined,
///   validator: (v) => v == null || v.isEmpty ? 'Required' : null,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.isPassword = false,
    this.isMultiline = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.initialValue,
    this.errorText,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isPassword;
  final bool isMultiline;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? initialValue;

  /// Externally supplied error text. Takes precedence over [validator].
  final String? errorText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          obscureText: _obscured,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          keyboardType: widget.isMultiline
              ? TextInputType.multiline
              : (widget.keyboardType ??
                  (widget.isPassword
                      ? TextInputType.visiblePassword
                      : TextInputType.text)),
          textInputAction: widget.isMultiline
              ? TextInputAction.newline
              : (widget.textInputAction ?? TextInputAction.next),
          maxLines: widget.isPassword ? 1 : (widget.isMultiline ? widget.maxLines : 1),
          minLines: widget.isMultiline ? (widget.minLines ?? 3) : null,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          buildCounter: widget.showCounter && widget.maxLength != null
              ? _buildCounter
              : (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.textTertiary)
                : null,
            suffixIcon: _buildSuffix(),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.textTertiary,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
        splashRadius: 20,
      );
    }
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, size: 20, color: AppColors.textTertiary),
        onPressed: widget.onSuffixTap,
        splashRadius: 20,
      );
    }
    return null;
  }

  Widget? _buildCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    return Text(
      '$currentLength / $maxLength',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: currentLength > (maxLength ?? 0)
            ? AppColors.error
            : AppColors.textTertiary,
      ),
    );
  }
}
