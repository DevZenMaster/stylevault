import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette — Luxury Dark
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2A2A2A);

  // Gold Accent
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF0D060);
  static const Color goldDark = Color(0xFF9B7E1E);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFF999990);
  static const Color textMuted = Color(0xFF555550);

  // Status
  static const Color success = Color(0xFF4CAF7C);
  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(0xFFE6A817);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF0D060), Color(0xFFD4AF37)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF141414)],
  );
}
