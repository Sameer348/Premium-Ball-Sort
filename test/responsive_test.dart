import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/app.dart';
import 'package:sort_sphere/features/achievements/achievements_screen.dart';
import 'package:sort_sphere/features/daily/daily_reward_sheet.dart';
import 'package:sort_sphere/features/daily/daily_screen.dart';
import 'package:sort_sphere/features/gameplay/game_screen.dart';
import 'package:sort_sphere/features/gameplay/level_complete_screen.dart';
import 'package:sort_sphere/features/gameplay/widgets/game_dialogs.dart';
import 'package:sort_sphere/features/levels/level_map_screen.dart';
import 'package:sort_sphere/features/settings/settings_screen.dart';
import 'package:sort_sphere/features/shop/shop_screen.dart';
import 'package:sort_sphere/game/engine/scoring.dart';
import 'package:sort_sphere/game/levels/level_catalog.dart';
import 'package:sort_sphere/models/game_mode.dart';
import 'package:sort_sphere/services/app_services.dart';
import 'package:sort_sphere/services/storage/key_value_store.dart';

/// Logical phone sizes from small Android / iPhone SE up to large phones,
/// plus a 7" tablet. Every screen must lay out without overflow on all.
const _sizes = <String, Size>{
  'small-android 360x640': Size(360, 640),
  'iphone-se 375x667': Size(375, 667),
  'mid-android 393x851': Size(393, 851),
  'pixel-pro 412x915': Size(412, 915),
  'iphone-pro-max 440x956': Size(440, 956),
  'tablet 800x1280': Size(800, 1280),
};

final _insane = LevelCatalog.level(301);

final _screens = <String, Widget Function()>{
  'game level 1': () => GameScreen(level: LevelCatalog.level(1), mode: GameMode.classic),
  'game 12 tubes': () => GameScreen(level: _insane, mode: GameMode.classic),
  'game time attack': () => GameScreen(level: LevelCatalog.level(25), mode: GameMode.timeAttack),
  'level complete': () => const LevelCompleteScreen(
        result: LevelResult(stars: 3, score: 12990, coins: 125, moves: 148, par: 150, seconds: 312, usedUndo: false, usedHint: false, perfect: true),
        coins: 125,
        mode: GameMode.classic,
        title: 'LEVEL 1234',
        best: 140,
      ),
  'level map': () => const LevelMapScreen(),
  'shop': () => const ShopScreen(),
  'daily': () => const DailyScreen(),
  'achievements': () => const AchievementsScreen(),
  'settings': () => const SettingsScreen(),
};

final _dialogs = <String, void Function(BuildContext)>{
  'daily reward': showDailyRewardSheet,
  'pause': showPauseDialog,
  'stuck': (c) => showStuckDialog(c, canAddTube: true),
  'fail': (c) => showFailDialog(c, timeUp: true, canContinue: true),
};

void main() {
  for (final scale in [1.0, 1.3]) {
    for (final entry in _sizes.entries) {
      testWidgets('no overflow at ${entry.key}, text x$scale', (tester) async {
        tester.view.physicalSize = entry.value * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) {
          final msg = d.exceptionAsString().split('\n').first;
          final src = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(d.toString())?.group(0) ?? '';
          errors.add('$msg $src');
        };

        final services = await AppServices.create(store: MemoryStore());
        await tester.pumpWidget(SortSphereApp(services: services));
        await tester.pump(const Duration(seconds: 1));
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);

        // Home sits under any auto-opened daily reward popup; close it.
        if (find.text('CLAIM').evaluate().isNotEmpty) {
          nav.pop();
          await tester.pump(const Duration(milliseconds: 500));
        }
        _check(errors, 'home');

        for (final s in _screens.entries) {
          nav.push(MaterialPageRoute<void>(builder: (_) => s.value()));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pump(const Duration(seconds: 2));
          _check(errors, s.key);
          nav.pop();
          await tester.pump(const Duration(milliseconds: 600));
        }

        for (final d in _dialogs.entries) {
          d.value(nav.context);
          await tester.pump(const Duration(milliseconds: 600));
          _check(errors, '${d.key} dialog');
          nav.pop();
          await tester.pump(const Duration(milliseconds: 600));
        }

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
        FlutterError.onError = previous;
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  }
}

void _check(List<String> errors, String where) {
  for (var i = 0; i < errors.length; i++) {
    if (!errors[i].startsWith('[')) errors[i] = '[$where] ${errors[i]}';
  }
}
