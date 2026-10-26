import 'package:flutter/material.dart';

import '../enums/app_enums.dart';

class AppColors {
  static const primary = Color(0xFFF2B705); // Vibrant Royal Industrial Blue
  static const primaryLight = Color(0xFFDBEAFE);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const backgroundDark = Color(0xFF0F172A);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);

  static Color priorityColor(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return const Color(0xFFDC2626);
      case Priority.high:
        return const Color(0xFFD97706);
      case Priority.medium:
        return const Color(0xFF2563EB);
      case Priority.low:
        return const Color(0xFF6B7280);
    }
  }

  static Color priorityBackgroundColor(Priority priority) {
    return priorityColor(priority).withValues(alpha: 0.12);
  }
}
