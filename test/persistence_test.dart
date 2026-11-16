import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/game/engine/scoring.dart';
import 'package:sort_sphere/models/achievement.dart';
import 'package:sort_sphere/models/app_settings.dart';
import 'package:sort_sphere/models/booster.dart';
import 'package:sort_sphere/models/cosmetics.dart';
import 'package:sort_sphere/models/game_mode.dart';
import 'package:sort_sphere/models/player_progress.dart';
import 'package:sort_sphere/repositories/progress_repository.dart';
import 'package:sort_sphere/services/analytics/analytics_service.dart';
import 'package:sort_sphere/services/storage/key_value_store.dart';
import 'package:sort_sphere/state/progress_controller.dart';

LevelResult res({int moves = 10, int par = 10, int stars = 3}) =>
    LevelResult(stars: stars, score: 1000, coins: 25, moves: moves, par: par, seconds: 30, usedUndo: false, usedHint: false, perfect: moves <= par);

void main() {
  test('PlayerProgress JSON round-trip keeps everything', () {
    final p = PlayerProgress(
      currentLevel: 12,
      stars: {1: 3, 2: 2},
      bestMoves: {1: 9},
      coins: 777,
      hints: 5,
      owned: {...defaultOwnedItems, 'ball_neon'},
      ballSkin: BallSkin.neon,
      theme: ThemeId.midnight,
      achievements: {'first_sort'},
      stats: {AchievementMetric.levelsCompleted: 11},
      dailyStreak: 4,
      removeAds: true,
    );
    final q = PlayerProgress.fromJson(p.toJson());
    expect(q.currentLevel, 12);
    expect(q.stars, {1: 3, 2: 2});
    expect(q.bestMoves, {1: 9});
    expect(q.coins, 777);
    expect(q.hints, 5);
    expect(q.owns('ball_neon'), isTrue);
    expect(q.ballSkin, BallSkin.neon);
    expect(q.achievements, {'first_sort'});
    expect(q.stat(AchievementMetric.levelsCompleted), 11);
    expect(q.dailyStreak, 4);
    expect(q.removeAds, isTrue);
  });

  test('repository persists progress and settings; tolerates corruption', () async {
    final store = MemoryStore();
    final repo = LocalProgressRepository(store);
    await repo.saveProgress(PlayerProgress(coins: 999, currentLevel: 7));
    await repo.saveSettings(const AppSettings(music: false, graphics: GraphicsQuality.low));
    final repo2 = LocalProgressRepository(store);
    expect(repo2.loadProgress().coins, 999);
    expect(repo2.loadProgress().currentLevel, 7);
    expect(repo2.loadSettings().music, isFalse);
    expect(repo2.loadSettings().graphics, GraphicsQuality.low);
    store.data['sortsphere.progress.v1'] = '{not json';
    expect(repo2.loadProgress().currentLevel, 1);
  });

  group('ProgressController', () {
    late MemoryStore store;
    late ProgressController pc;
    var now = DateTime(2026, 11, 15, 10);
    setUp(() {
      store = MemoryStore();
      now = DateTime(2026, 11, 15, 10);
      pc = ProgressController(repo: LocalProgressRepository(store), analytics: DebugAnalyticsService(), clock: () => now);
    });

    test('classic completion advances level, keeps best stars, saves', () {
      final start = pc.coins;
      pc.recordResult(mode: GameMode.classic, level: 1, r: res(stars: 2), tubesCompleted: 3);
      expect(pc.value.currentLevel, 2);
      expect(pc.value.stars[1], 2);
      pc.recordResult(mode: GameMode.classic, level: 1, r: res(stars: 1), tubesCompleted: 3);
      expect(pc.value.stars[1], 2, reason: 'best stars kept');
      expect(pc.value.currentLevel, 2, reason: 'replay does not skip ahead');
      expect(pc.coins, greaterThan(start));
      expect(LocalProgressRepository(store).loadProgress().currentLevel, 2);
    });

    test('achievements unlock once and pay out', () async {
      final unlocked = <String>[];
      final sub = pc.unlocks.listen((a) => unlocked.add(a.id));
      pc.recordResult(mode: GameMode.classic, level: 1, r: res(), tubesCompleted: 3);
      pc.recordResult(mode: GameMode.classic, level: 2, r: res(), tubesCompleted: 3);
      await Future<void>.delayed(Duration.zero);
      expect(unlocked.where((i) => i == 'first_sort').length, 1);
      expect(pc.value.achievements, contains('first_sort'));
      await sub.cancel();
    });

    test('boosters: consume, buy, grant', () {
      final h = pc.inventory(Booster.hint);
      expect(pc.consumeBooster(Booster.hint), isTrue);
      expect(pc.inventory(Booster.hint), h - 1);
      pc.addCoins(1000);
      expect(pc.buyBooster(Booster.hint, count: 2), isTrue);
      expect(pc.inventory(Booster.hint), h + 1);
    });

    test('cosmetics require ownership to select', () {
      pc.selectBallSkin(BallSkin.galaxy);
      expect(pc.value.ballSkin, BallSkin.classic);
      pc.addCoins(5000);
      expect(pc.buyItem(BallSkin.galaxy.id, BallSkin.galaxy.price), isTrue);
      pc.selectBallSkin(BallSkin.galaxy);
      expect(pc.value.ballSkin, BallSkin.galaxy);
    });

    test('7-day reward cycle advances daily and resets after a gap', () {
      expect(pc.claimableRewardIndex, 0);
      expect(pc.claimDailyReward()!.day, 1);
      expect(pc.claimableRewardIndex, isNull, reason: 'once per day');
      now = DateTime(2026, 11, 16, 9);
      expect(pc.claimDailyReward()!.day, 2);
      now = DateTime(2026, 11, 17, 9);
      final hints = pc.inventory(Booster.hint);
      expect(pc.claimDailyReward()!.day, 3);
      expect(pc.inventory(Booster.hint), hints + 2);
      now = DateTime(2026, 11, 20, 9); // missed days
      expect(pc.claimableRewardIndex, 0);
    });

    test('daily challenge pays once and builds a streak', () {
      final c0 = pc.coins;
      pc.recordResult(mode: GameMode.daily, level: 0, r: res(), tubesCompleted: 4);
      final c1 = pc.coins;
      expect(c1 - c0, greaterThan(100));
      expect(pc.value.dailyStreak, 1);
      pc.recordResult(mode: GameMode.daily, level: 0, r: res(), tubesCompleted: 4);
      expect(pc.value.dailyStreak, 1);
      now = DateTime(2026, 11, 16, 8);
      pc.recordResult(mode: GameMode.daily, level: 0, r: res(), tubesCompleted: 4);
      expect(pc.value.dailyStreak, 2);
    });

    test('reset wipes progress', () async {
      pc.recordResult(mode: GameMode.classic, level: 1, r: res(), tubesCompleted: 3);
      await pc.resetProgress();
      expect(pc.value.currentLevel, 1);
      expect(pc.value.stars, isEmpty);
    });
  });
}
