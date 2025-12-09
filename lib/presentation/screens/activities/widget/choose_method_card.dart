// lib/widgets/choose_method_card.dart

import 'package:flutter/material.dart';

class ChooseMethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color splashColor;
  final String title;
  final String description;
  final String hint;
  final Color hintColor;
  final VoidCallback onTap;
  final Color borderColor;

  const ChooseMethodCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.splashColor,
    required this.title,
    required this.description,
    required this.hint,
    required this.hintColor,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF1B2A41);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: splashColor,
                ),
                child: Icon(icon, size: 48, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                hint,
                style: TextStyle(
                  color: hintColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
