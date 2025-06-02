import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  // Font Families
  static const String primaryFont = 'Inter';
  static const String secondaryFont = 'Poppins';
  static const String displayFont = 'Space Grotesk';
  static const String monoFont = 'JetBrains Mono';

  // Font Weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // Display Styles (Large Headlines)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 57,
    fontWeight: bold,
    height: 1.12,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 45,
    fontWeight: bold,
    height: 1.16,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 36,
    fontWeight: semiBold,
    height: 1.22,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.29,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: medium,
    height: 1.27,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
    color: AppColors.textTertiary,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  // Gym App Specific Styles
  static const TextStyle gymName = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.22,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle gymAddress = TextStyle(
    fontFamily: primaryFont,
    fontSize: 13,
    fontWeight: regular,
    height: 1.38,
    letterSpacing: 0.25,
    color: AppColors.textTertiary,
  );

  static const TextStyle gymDistance = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.4,
    color: AppColors.secondary,
  );

  static const TextStyle weightValue = TextStyle(
    fontFamily: monoFont,
    fontSize: 32,
    fontWeight: bold,
    height: 1.25,
    letterSpacing: -0.5,
    color: AppColors.weightTracker,
  );

  static const TextStyle weightUnit = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppColors.textSecondary,
  );

  static const TextStyle progressPercentage = TextStyle(
    fontFamily: monoFont,
    fontSize: 24,
    fontWeight: bold,
    height: 1.33,
    letterSpacing: 0,
    color: AppColors.progressBar,
  );

  static const TextStyle scheduleTime = TextStyle(
    fontFamily: monoFont,
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.workoutTime,
  );

  static const TextStyle caloriesCount = TextStyle(
    fontFamily: monoFont,
    fontSize: 20,
    fontWeight: bold,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.caloriesBurned,
  );

  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0.1,
    color: AppColors.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.white,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  // Utility Methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withOpacity(opacity));
  }

  // Font loading helper (add to pubspec.yaml)
  static const List<String> requiredFonts = [
    'Inter',
    'Poppins',
    'Space Grotesk',
    'JetBrains Mono',
  ];
}
