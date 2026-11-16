import 'package:flutter/material.dart';

import '../../models/achievement.dart';

/// Constant icon mapping (keeps icon-font tree shaking working).
IconData achievementIcon(Achievement a) => switch (a.id) {
      'first_sort' => Icons.check_circle_rounded,
      'levels_10' => Icons.trending_up_rounded,
      'levels_50' => Icons.auto_graph_rounded,
      'levels_100' => Icons.military_tech_rounded,
      'levels_500' => Icons.workspace_premium_rounded,
      'levels_1000' => Icons.emoji_events_rounded,
      'perfect_sorter' => Icons.verified_rounded,
      'no_undo' => Icons.block_rounded,
      'speed_sorter' => Icons.bolt_rounded,
      'daily_streak' => Icons.local_fire_department_rounded,
      'color_master' => Icons.palette_rounded,
      'puzzle_master' => Icons.extension_rounded,
      _ => Icons.star_rounded,
    };
