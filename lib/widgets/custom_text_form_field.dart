import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final void Function()? onTap;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;
  final String? initialValue;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final bool? filled;
  final Color? fillColor;
  final String? errorText;
  final String? helperText;
  final String? counterText;
  final bool? isDense;
  final double? borderRadius;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.initialValue,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.filled,
    this.fillColor,
    this.errorText,
    this.helperText,
    this.counterText,
    this.isDense,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius!),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outline,
        width: 1.0,
      ),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofocus: autofocus,
      focusNode: focusNode,
      enabled: enabled,
      initialValue: initialValue,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: enabled
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border ?? defaultBorder,
        enabledBorder: enabledBorder ?? defaultBorder,
        focusedBorder: focusedBorder ??
            defaultBorder.copyWith(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2.0,
              ),
            ),
        errorBorder: errorBorder ??
            defaultBorder.copyWith(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.0,
              ),
            ),
        focusedErrorBorder: focusedErrorBorder ??
            defaultBorder.copyWith(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2.0,
              ),
            ),
        filled: filled ?? true,
        fillColor: fillColor ?? Theme.of(context).colorScheme.surface,
        errorText: errorText,
        helperText: helperText,
        counterText: counterText,
        isDense: isDense,
        errorStyle: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),
    );
  }
}
