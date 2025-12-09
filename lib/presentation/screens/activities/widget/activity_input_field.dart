import 'package:flutter/material.dart';

class ActivityInputField extends StatelessWidget {
  final String label;
  final Widget child;

  const ActivityInputField({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 30), // Memberikan jarak di bawah setiap input
      ],
    );
  }
}
