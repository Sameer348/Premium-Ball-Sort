import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/transitions.dart';
import '../../game/levels/level_catalog.dart';
import '../../models/daily_challenge.dart';
import '../../models/difficulty.dart';
import '../../models/game_mode.dart';
import '../../models/level_data.dart';
import '../../state/progress_controller.dart';
import 'game_screen.dart';

/// Resolves the right puzzle for a mode (off the UI thread when it needs
/// generating) and opens the game screen.
class GameLauncher {
  GameLauncher._();

  static final Map<int, LevelData> _cache = {};

  static Future<LevelData> campaignLevel(int n) async {
    if (n <= LevelCatalog.handcraftedCount) return LevelCatalog.level(n);
    final hit = _cache[n];
    if (hit != null) return hit;
    final l = await Isolate.run(() => generateCampaignLevel(n));
    if (_cache.length > 8) _cache.remove(_cache.keys.first);
    return _cache[n] = l;
  }

  /// Pre-generates the next level while the player is celebrating.
  static void prefetch(int n) {
    if (n > LevelCatalog.handcraftedCount && !_cache.containsKey(n)) campaignLevel(n);
  }

  static Future<void> play(BuildContext context, {required GameMode mode, int? level, bool replace = false}) async {
    final nav = Navigator.of(context);
    final progress = context.read<ProgressController>();
    var done = false;
    Route<void>? spinner;
    // Only show a spinner if generation is noticeably slow.
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (done || !nav.mounted) return;
      spinner = PageRouteBuilder<void>(
        opaque: false,
        barrierColor: const Color(0x66040814),
        pageBuilder: (_, _, _) => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
      nav.push(spinner!);
    });

    final endlessIndex = mode == GameMode.endless ? (level ?? progress.value.endlessIndex) : 0;
    final LevelData data;
    try {
      data = await levelFor(
        mode,
        campaign: level ?? progress.value.currentLevel,
        endlessIndex: endlessIndex,
        dateKey: dateKeyOf(DateTime.now()),
        seed: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      );
    } finally {
      // Never leave the spinner up, even if generation fails.
      done = true;
      if (nav.mounted && spinner != null) nav.removeRoute(spinner!);
    }
    if (mode == GameMode.daily) progress.recordDailyAttempt();
    if (!nav.mounted) return;

    final route = Transitions.zoom<void>(GameScreen(level: data, mode: mode, endlessIndex: endlessIndex));
    replace ? await nav.pushReplacement(route) : await nav.push(route);
  }

  /// The puzzle for [mode], generated off the UI thread.
  ///
  /// Kept separate from [play] on purpose: an `Isolate.run` closure created
  /// inside [play] would share its context (navigator, routes) and fail to
  /// send with "object is unsendable". Here the closures only capture ints.
  static Future<LevelData> levelFor(
    GameMode mode, {
    required int campaign,
    required int endlessIndex,
    required int dateKey,
    required int seed,
  }) {
    switch (mode) {
      case GameMode.classic:
        return campaignLevel(campaign);
      case GameMode.daily:
        return Isolate.run(() => generateDailyLevel(dateKey));
      case GameMode.endless:
        return Isolate.run(() => generateEndlessLevel(endlessIndex));
      case GameMode.timeAttack:
        return Isolate.run(() => generateSpecialLevel([seed, Difficulty.medium.index]));
      case GameMode.perfect:
        return Isolate.run(() => generateSpecialLevel([seed, Difficulty.hard.index]));
    }
  }
}
