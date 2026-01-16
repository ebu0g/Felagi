import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final int? maxLines;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.maxLines,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // If obscureText is true, maxLines must be 1 (Flutter constraint)
    final effectiveMaxLines = obscureText ? 1 : maxLines;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: effectiveMaxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
