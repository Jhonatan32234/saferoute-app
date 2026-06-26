// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Paleta principal basada en Figma
  static const Color primary = Color(0xFF2563EB);      // Azul principal
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryBg = Color(0xFFEFF6FF);
  static const Color primaryBorder = Color(0xFFBFDBFE);

  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleBg = Color(0xFFF5F3FF);

  // Slate
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Riesgo
  static const Color riskLow = Color(0xFF16A34A);
  static const Color riskMedium = Color(0xFFD97706);
  static const Color riskHigh = Color(0xFFDC2626);
}

class RiskColors {
  static Color getColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'bajo':
      case 'verde':
      case 'low':
        return AppColors.riskLow;
      case 'medio':
      case 'amarillo':
      case 'medium':
        return AppColors.riskMedium;
      case 'alto':
      case 'rojo':
      case 'high':
        return AppColors.riskHigh;
      default:
        return AppColors.slate400;
    }
  }

  static String getLabel(String risk) {
    switch (risk.toLowerCase()) {
      case 'bajo':
      case 'verde':
      case 'low':
        return 'Bajo';
      case 'medio':
      case 'amarillo':
      case 'medium':
        return 'Medio';
      case 'alto':
      case 'rojo':
      case 'high':
        return 'Alto';
      default:
        return 'Desconocido';
    }
  }
}