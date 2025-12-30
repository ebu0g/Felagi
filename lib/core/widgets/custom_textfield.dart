import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller; // <- Add this

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller, // <- Add this
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // <- Make sure it's used here
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }
}
