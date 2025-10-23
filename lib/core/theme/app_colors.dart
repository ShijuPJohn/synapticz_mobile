import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors (matching web app's cyan/blue theme)
  static const Color primary = Color(0xFF0891B2); // cyan-600
  static const Color primaryLight = Color(0xFF22D3EE); // cyan-400
  static const Color primaryDark = Color(0xFF0E7490); // cyan-700

  // Secondary Colors (indigo/purple for AI features)
  static const Color secondary = Color(0xFF6366F1); // indigo-500
  static const Color secondaryLight = Color(0xFF818CF8); // indigo-400
  static const Color accent = Color(0xFF8B5CF6); // purple-500
  static const Color accentLight = Color(0xFFA78BFA); // purple-400

  // Success/Learn Colors (emerald for SynLearn)
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color successLight = Color(0xFF34D399); // emerald-400

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC); // slate-50
  static const Color backgroundDark = Color(0xFF0F172A); // slate-900
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B); // slate-800

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color textTertiary = Color(0xFF94A3B8); // slate-400
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400

  // Functional Colors
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color info = Color(0xFF3B82F6); // blue-500

  // Gradient Colors (for hero sections & cards)
  static const LinearGradient heroDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // slate-900
      Color(0xFF1E293B), // slate-800
      Color(0xFF0F172A), // slate-900
    ],
  );

  static const LinearGradient synlearnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // emerald-500
      Color(0xFF06B6D4), // cyan-500
    ],
  );

  static const LinearGradient quizgenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6366F1), // indigo-500
      Color(0xFF8B5CF6), // purple-500
    ],
  );

  static const LinearGradient articlegenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4), // cyan-500
      Color(0xFF3B82F6), // blue-500
    ],
  );

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0); // slate-200
  static const Color borderDark = Color(0xFF334155); // slate-700
}
