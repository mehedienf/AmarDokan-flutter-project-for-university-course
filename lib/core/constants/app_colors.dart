import 'package:flutter/material.dart';

/// App এর সব colors এখানে define করা আছে
/// একই জায়গায় থাকলে পরে color change করা সহজ হয়
class AppColors {
  AppColors._(); // Private constructor — এই class এর object create করা যাবে না

  // Primary Brand Color (Amar Dokan এর main color)
  static const Color primary = Color(0xFF2E7D32); // গাঢ় সবুজ — ব্যবসায়িক trust বোঝায়
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  // Secondary Color (Accent)
  static const Color secondary = Color(0xFFFF6F00); // কমলা — call-to-action buttons
  static const Color secondaryLight = Color(0xFFFFA040);
  static const Color secondaryDark = Color(0xFFC43E00);

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // সবুজ — successful sale
  static const Color warning = Color(0xFFFF9800); // কমলা — low stock warning
  static const Color error = Color(0xFFE53935); // লাল — error messages
  static const Color info = Color(0xFF2196F3); // নীল — info messages

  // Neutral Colors (Background ও text এর জন্য)
  static const Color background = Color(0xFFF5F5F5); // হালকা ধূসর background
  static const Color surface = Color(0xFFFFFFFF); // Card এর background
  static const Color textPrimary = Color(0xFF212121); // প্রধান text
  static const Color textSecondary = Color(0xFF757575); // গৌণ text
  static const Color divider = Color(0xFFE0E0E0); // Divider line

  // Dashboard specific colors
  static const Color salesCard = Color(0xFF1976D2); // Sales card color
  static const Color profitCard = Color(0xFF388E3C); // Profit card color
  static const Color stockCard = Color(0xFFF57C00); // Stock card color
  static const Color lowStockCard = Color(0xFFD32F2F); // Low stock alert color
}
