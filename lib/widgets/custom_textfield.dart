import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {

  String? hintText;
  bool isPassword;
  TextEditingController textEditingController;
  TextInputAction inputAction;
  Widget? leftIcon;
  Widget? rightIcon;
  bool? isDisable;
  VoidCallback? onTap;
  TextInputType? keyboardType;
  FloatingLabelBehavior? floatingLabelBehavior;
  int? maxLines;
  int? minLines;
  int? maxLength;
  String? labelText;
  double? textSize;
  TextCapitalization? textCapitalization;

  InputBorder? focusedBorder;
  InputBorder? enabledBorder;

  final Function(String value)? onSubmit;
  final Function(String value)? onValueChange;


  CustomTextField({
    this.hintText,
    required this.textEditingController,
    this.isPassword = false,
    this.inputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.floatingLabelBehavior,
    this.leftIcon,
    this.rightIcon,
    this.onSubmit,
    this.onValueChange,
    this.isDisable,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.labelText,
    this.textSize,
    this.focusedBorder,
    this.enabledBorder,
    this.onTap,
    this.textCapitalization});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      decoration: InputDecoration(
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor ?? (isDark ? Colors.white10 : Colors.grey[100]),
          contentPadding: const EdgeInsets.all(8),
          counterText: "",
          enabledBorder: enabledBorder ?? OutlineInputBorder(
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.35)),
          ),
          focusedBorder: focusedBorder ?? OutlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          // pass the hint text parameter here
          labelText: labelText ?? hintText,
          hintText: hintText ?? "",
          labelStyle: theme.inputDecorationTheme.labelStyle ?? TextStyle(color: theme.hintColor, fontSize: 14),
          hintStyle: theme.inputDecorationTheme.hintStyle ?? TextStyle(color: theme.hintColor.withOpacity(0.8), fontSize: 14),
          prefixIcon: leftIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: (isDark
                            ? Colors.white
                            : Colors.black87)
                        .withOpacity(0.48),
                  ),
                  child: leftIcon!,
                )
              : null,
          suffixIcon: rightIcon != null
              ? IconTheme(
            data: IconThemeData(
              color: (isDark
                  ? Colors.white
                  : Colors.black87)
                  .withOpacity(0.48),
            ),
            child: rightIcon!,
          )
              : null,
          floatingLabelBehavior: floatingLabelBehavior ??
              FloatingLabelBehavior.auto
      ),
      style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black), fontSize: textSize ?? 14),
      controller: textEditingController,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      minLines: minLines ?? 1,
      maxLength: maxLength,
      textInputAction: inputAction,
      readOnly: isDisable ?? false,
      cursorColor: theme.colorScheme.primary,
      obscureText: isPassword,
      onChanged: onValueChange,
      onSubmitted: onSubmit,
      onTap: onTap,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
    );
  }
}