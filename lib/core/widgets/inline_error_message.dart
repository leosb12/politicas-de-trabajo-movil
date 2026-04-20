import 'package:flutter/material.dart';

class InlineErrorMessage extends StatelessWidget {
  const InlineErrorMessage({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFA7A1)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF8E221A)),
      ),
    );
  }
}
