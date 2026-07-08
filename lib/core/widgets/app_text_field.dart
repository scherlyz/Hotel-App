import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmit;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final String? labelText;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
    this.onSubmit,
    this.onChanged,
    this.maxLines = 1,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: 14,
          ),

          isDense: true,

          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),

          prefixIcon: Icon(prefixIcon),
          suffixIcon: suffixIcon,
          labelText: labelText,

          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
        ),
        ),
    );
  }
}