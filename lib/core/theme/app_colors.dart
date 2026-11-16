import 'package:flutter/material.dart';

/// Single source of truth for color. Meaning is consistent everywhere:
/// cyan/blue = primary action, violet = premium, green = success,
/// gold = rewards, coral = error, white = key info, blue-gray = secondary.
class AppColors {
  AppColors._();

  // Surfaces (≈70% of the screen)
  static const background = Color(0xFF080D1A);
  static const secondary = Color(0xFF0F172A);
  static const surface = Color(0xFF151F35);
  static const elevated = Color(0xFF1B2944);
  static const card = Color(0xFF22304D);

  // Glass (≈20%)
  static const glass = Color(0x14FFFFFF); // 8%
  static const glassStrong = Color(0x1FFFFFFF); // 12%
  static const glassBorder = Color(0x26FFFFFF);
  static const glassFaint = Color(0x0FFFFFFF); // 6%

  // Accents (≈10%)
  static const cyan = Color(0xFF36E4FF);
  static const blue = Color(0xFF5C7CFF);
  static const violet = Color(0xFF9B6CFF);
  static const purple = Color(0xFFC084FC);
  static const success = Color(0xFF36E0A0);
  static const gold = Color(0xFFFFD166);
  static const amber = Color(0xFFFFB347);
  static const coral = Color(0xFFFF647C);

  // Text
  static const textPrimary = Color(0xFFF8FAFF);
  static const textSecondary = Color(0xFFB4C0D8);
  static const textMuted = Color(0xFF71809D);
  static const textDisabled = Color(0xFF4D5A73);

  static const primaryGradient = LinearGradient(
    colors: [cyan, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const premiumGradient = LinearGradient(
    colors: [purple, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const goldGradient = LinearGradient(
    colors: [gold, amber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const successGradient = LinearGradient(
    colors: [Color(0xFF5BF0B8), success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Ball palette — tuned for distinct hue *and* lightness so neighbours stay
/// separable on dim or warm displays. Each ball also has a shape glyph
/// (see `BallGlyph`) for players who enable color symbols.
class BallPalette {
  BallPalette._();

  static const colors = <Color>[
    Color(0xFFFF5C7A), // 0 red
    Color(0xFF36DDF5), // 1 cyan
    Color(0xFFFFD166), // 2 yellow
    Color(0xFF9B6CFF), // 3 purple
    Color(0xFF35D39A), // 4 green
    Color(0xFFFF9F43), // 5 orange
    Color(0xFF5C7CFF), // 6 blue
    Color(0xFFF472B6), // 7 pink
    Color(0xFF2DD4BF), // 8 teal
    Color(0xFFF8FAFF), // 9 white
  ];

  static const names = ['Red', 'Cyan', 'Yellow', 'Purple', 'Green', 'Orange', 'Blue', 'Pink', 'Teal', 'White'];

  static Color of(int i) => colors[i % colors.length];
}
