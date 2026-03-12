import 'package:flutter/material.dart';

/// Design System - Colors
/// Sử dụng semantic name, không hardcode màu trong UI
class AppColors {
  AppColors._();

  // Primary (Updated to use Secondary green theme as requested)
  static const Color primary = Color(0xFF26A69A);
  static const Color primaryLight = Color(0xFF64D8CB);
  static const Color primaryDark = Color(0xFF00766C);

  // Secondary
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF64D8CB);
  static const Color secondaryDark = Color(0xFF00766C);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color error = Color(0xFFD32F2F);
}
