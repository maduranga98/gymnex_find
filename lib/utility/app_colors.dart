import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5A4FCF);
  static const Color primaryLight = Color(0xFF8B7EFF);

  // Secondary Colors
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryDark = Color(0xFF00B894);
  static const Color secondaryLight = Color(0xFF55EAE6);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentDark = Color(0xFFE55656);
  static const Color accentLight = Color(0xFFFF8E8E);

  // Background Colors
  static const Color background = Color(0xFF0D1117);
  static const Color backgroundSecondary = Color(0xFF161B22);
  static const Color backgroundTertiary = Color(0xFF21262D);
  static const Color surface = Color(0xFF1C2128);
  static const Color surfaceVariant = Color(0xFF2D333B);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B7C3);
  static const Color textTertiary = Color(0xFF8B949E);
  static const Color textDisabled = Color(0xFF6E7681);

  // Status Colors
  static const Color success = Color(0xFF2EA043);
  static const Color successLight = Color(0xFF56D364);
  static const Color warning = Color(0xFFD29922);
  static const Color warningLight = Color(0xFFE3B341);
  static const Color error = Color(0xFFDA3633);
  static const Color errorLight = Color(0xFFF85149);
  static const Color info = Color(0xFF316DCA);
  static const Color infoLight = Color(0xFF58A6FF);

  // Gym Specific Colors
  static const Color gymCard = Color(0xFF1E2328);
  static const Color gymCardBorder = Color(0xFF30363D);
  static const Color progressBar = Color(0xFF238636);
  static const Color progressBarBackground = Color(0xFF21262D);
  static const Color weightTracker = Color(0xFFFF6B6B);
  static const Color caloriesBurned = Color(0xFFFFA500);
  static const Color workoutTime = Color(0xFF00CEC9);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Border Colors
  static const Color borderPrimary = Color(0xFF30363D);
  static const Color borderSecondary = Color(0xFF21262D);
  static const Color borderAccent = Color(0xFF58A6FF);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00CEC9), Color(0xFF00B894)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2328), Color(0xFF2D333B)],
  );

  // Elevation Colors (for Material 3)
  static const Color elevation1 = Color(0xFF1C2128);
  static const Color elevation2 = Color(0xFF21262D);
  static const Color elevation3 = Color(0xFF2D333B);
  static const Color elevation4 = Color(0xFF373E47);
  static const Color elevation5 = Color(0xFF424950);

  // Utility Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
