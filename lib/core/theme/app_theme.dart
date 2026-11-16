import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.violet,
        surface: AppColors.surface,
        error: AppColors.coral,
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppText.h1,
        titleLarge: AppText.h2,
        titleMedium: AppText.h3,
        bodyMedium: AppText.body,
        bodySmall: AppText.small,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.elevated),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
