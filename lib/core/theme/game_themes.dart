import 'package:flutter/material.dart';

import '../../models/cosmetics.dart';
import 'app_colors.dart';

/// Visual definition of a board theme. Ball colors are never altered by a
/// theme (readability first); themes change ambience, tubes and accents.
class GameThemeSpec {
  const GameThemeSpec({
    required this.top,
    required this.bottom,
    required this.glowA,
    required this.glowB,
    required this.accent,
    required this.particle,
    this.tubeTint = Colors.white,
    this.vignette = 0.55,
  });

  final Color top;
  final Color bottom;

  /// Two soft ambient light blobs.
  final Color glowA;
  final Color glowB;
  final Color accent;
  final Color particle;
  final Color tubeTint;
  final double vignette;

  static GameThemeSpec of(ThemeId id) => switch (id) {
        ThemeId.midnight => const GameThemeSpec(top: Color(0xFF0D1426), bottom: AppColors.background, glowA: Color(0xFF2A4DFF), glowB: Color(0xFF36E4FF), accent: AppColors.cyan, particle: Color(0xFF8FB8FF)),
        ThemeId.ocean => const GameThemeSpec(top: Color(0xFF06243A), bottom: Color(0xFF041320), glowA: Color(0xFF00A6C8), glowB: Color(0xFF2DD4BF), accent: Color(0xFF3FE0FF), particle: Color(0xFF8FF3FF), tubeTint: Color(0xFFCFFAFF)),
        ThemeId.aurora => const GameThemeSpec(top: Color(0xFF0B1A2A), bottom: Color(0xFF070C18), glowA: Color(0xFF36E0A0), glowB: Color(0xFF9B6CFF), accent: Color(0xFF5BF0B8), particle: Color(0xFFB6FFE4), tubeTint: Color(0xFFE5FFF5)),
        ThemeId.candy => const GameThemeSpec(top: Color(0xFF2A1430), bottom: Color(0xFF140A1C), glowA: Color(0xFFF472B6), glowB: Color(0xFFFFB347), accent: Color(0xFFFF8FC8), particle: Color(0xFFFFC6E4), tubeTint: Color(0xFFFFE6F3)),
        ThemeId.sunset => const GameThemeSpec(top: Color(0xFF2B1426), bottom: Color(0xFF120A18), glowA: Color(0xFFFF7A59), glowB: Color(0xFFFFB347), accent: Color(0xFFFFB347), particle: Color(0xFFFFD6A8), tubeTint: Color(0xFFFFEEDD)),
        ThemeId.galaxy => const GameThemeSpec(top: Color(0xFF140D2E), bottom: Color(0xFF06040F), glowA: Color(0xFF9B6CFF), glowB: Color(0xFF5C7CFF), accent: AppColors.purple, particle: Color(0xFFE3D4FF), tubeTint: Color(0xFFEDE4FF), vignette: 0.7),
        ThemeId.forest => const GameThemeSpec(top: Color(0xFF0C2119), bottom: Color(0xFF06120D), glowA: Color(0xFF35D39A), glowB: Color(0xFFB6E36B), accent: Color(0xFF6BE3A8), particle: Color(0xFFD7FFC4), tubeTint: Color(0xFFE8FFEE)),
        ThemeId.minimal => const GameThemeSpec(top: Color(0xFF161A22), bottom: Color(0xFF0E1117), glowA: Color(0xFF3A4254), glowB: Color(0xFF2A303D), accent: Color(0xFFDDE3EE), particle: Color(0xFF9AA4B8), vignette: 0.3),
        ThemeId.cyber => const GameThemeSpec(top: Color(0xFF0A0F24), bottom: Color(0xFF05060F), glowA: Color(0xFFFF2BD6), glowB: Color(0xFF00F0FF), accent: Color(0xFF00F0FF), particle: Color(0xFFFF8BEE), tubeTint: Color(0xFFD9FCFF)),
      };
}
