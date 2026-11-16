import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale. Uses the platform font (SF Pro / Roboto) with tuned
/// weights and tracking — no bundled font files needed.
class AppText {
  AppText._();

  static const display = TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.textPrimary, height: 1);
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textPrimary);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const h3 = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.35);
  static const small = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: AppColors.textMuted);
  static const button = TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF061021));
  static const number = TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFeatures: [FontFeature.tabularFigures()]);
}
