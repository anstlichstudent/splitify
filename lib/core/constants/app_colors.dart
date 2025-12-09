import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor

  // Primary colors
  static const Color darkBlue = Color(0xFF000518);
  static const Color primaryColor = Color(0xFF3B5BFF);
  static const Color cardColor = Color(0xFF1A1F2E);
  static const Color dividerColor = Color(0xFF2A3142);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFFF4444);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Text colors
  static const Color textLight = Colors.white;
  static const Color textMedium = Color(0xFFB0BEC5);
  static const Color textDark = Color(0xFF455A64);

  // Opacity variants
  static Color primaryOpacity10 = primaryColor.withOpacity(0.1);
  static Color primaryOpacity20 = primaryColor.withOpacity(0.2);
  static Color primaryOpacity50 = primaryColor.withOpacity(0.5);

  // Gradients
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColor.withOpacity(0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
