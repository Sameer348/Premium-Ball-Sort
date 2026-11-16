import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/economy.dart';
import '../game/engine/scoring.dart';
import '../models/achievement.dart';
import '../models/booster.dart';
import '../models/cosmetics.dart';
import '../models/daily_challenge.dart';
import '../models/daily_reward.dart';
import '../models/game_mode.dart';
import '../models/player_progress.dart';
import '../repositories/progress_repository.dart';
import '../services/analytics/analytics_service.dart';

/// Owns persistent player state: progress, economy, cosmetics,
/// achievements, daily systems. All mutations save immediately.
class ProgressController extends ChangeNotifier {
  ProgressController({required ProgressRepository repo, required this.analytics, DateTime Function()? clock})
      : _repo = repo,
        _clock = clock ?? DateTime.now,
        _p = repo.loadProgress();

  final ProgressRepository _repo;
  final AnalyticsService analytics;
  final DateTime Function() _clock;
  PlayerProgress _p;

  /// Achievements unlocked since last read (UI shows a toast for each).
  final StreamController<Achievement> _unlocks = StreamController.broadcast();
  Stream<Achievement> get unlocks => _unlocks.stream;

  PlayerProgress get value => _p;
  int get coins => _p.coins;
  int todayKey() => dateKeyOf(_clock());

  void _set(PlayerProgress next) {
    _p = next;
    unawaited(_repo.saveProgress(next));
    notifyListeners();
  }

  // ------------------------------------------------------------- economy

  void addCoins(int n) => _set(_p.copyWith(coins: _p.coins + n));

  bool spendCoins(int n) {
    if (_p.coins < n) return false;
    _set(_p.copyWith(coins: _p.coins - n));
    return true;
  }

  int inventory(Booster b) => switch (b) {
        Booster.hint => _p.hints,
        Booster.undo => _p.undos,
        Booster.extraTube => _p.extraTubes,
        Booster.shuffle => _p.shuffles,
      };

  static int priceOf(Booster b) => switch (b) {
        Booster.hint => Economy.hintPrice,
        Booster.undo => Economy.undoPrice,
        Booster.extraTube => Economy.extraTubePrice,
        Booster.shuffle => Economy.shufflePrice,
      };

  void grantBooster(Booster b, int n) => _set(switch (b) {
        Booster.hint => _p.copyWith(hints: _p.hints + n),
        Booster.undo => _p.copyWith(undos: _p.undos + n),
        Booster.extraTube => _p.copyWith(extraTubes: _p.extraTubes + n),
        Booster.shuffle => _p.copyWith(shuffles: _p.shuffles + n),
      });

  /// Consumes one from inventory. False when none left.
  bool consumeBooster(Booster b) {
    if (inventory(b) <= 0) return false;
    grantBooster(b, -1);
    return true;
  }

  bool buyBooster(Booster b, {int count = 1}) {
    if (!spendCoins(priceOf(b) * count)) return false;
    grantBooster(b, count);
    return true;
  }

  // ----------------------------------------------------------- cosmetics

  bool buyItem(String id, int price) {
    if (_p.owns(id)) return true;
    if (_p.coins < price) return false;
    _set(_p.copyWith(coins: _p.coins - price, owned: {..._p.owned, id}));
    analytics.log(AnalyticsEvent.skinUnlocked, {'id': id});
    return true;
  }

  void selectBallSkin(BallSkin s) {
    if (_p.owns(s.id)) _set(_p.copyWith(ballSkin: s));
  }

  void selectTubeSkin(TubeSkin s) {
    if (_p.owns(s.id)) _set(_p.copyWith(tubeSkin: s));
  }

  void selectTheme(ThemeId t) {
    if (_p.owns(t.id)) _set(_p.copyWith(theme: t));
  }

  // ------------------------------------------------------------ progress

  /// Records a finished puzzle and returns coins awarded.
  int recordResult({required GameMode mode, required int level, required LevelResult r, required int tubesCompleted, int endlessIndex = 0}) {
    var p = _p;
    final stats = {...p.stats};
    void inc(AchievementMetric m, [int by = 1]) => stats[m] = (stats[m] ?? 0) + by;

    var coins = r.coins;
    switch (mode) {
      case GameMode.classic:
        final prevStars = p.stars[level] ?? 0;
        final stars = {...p.stars, level: r.stars > prevStars ? r.stars : prevStars};
        final bestM = {...p.bestMoves};
        if ((bestM[level] ?? 1 << 30) > r.moves) bestM[level] = r.moves;
        final bestS = {...p.bestScores};
        if ((bestS[level] ?? 0) < r.score) bestS[level] = r.score;
        if (prevStars < 3 && r.stars == 3) inc(AchievementMetric.threeStarLevels);
        p = p.copyWith(
          stars: stars,
          bestMoves: bestM,
          bestScores: bestS,
          currentLevel: level >= p.currentLevel ? level + 1 : p.currentLevel,
        );
      case GameMode.daily:
        final today = todayKey();
        final rec = p.daily.dateKey == today ? p.daily : DailyChallengeRecord(dateKey: today);
        final first = !rec.completed;
        if (first) coins += Economy.dailyChallengeCoins;
        final streak = !first
            ? p.dailyStreak
            : (p.lastDailyCompleted == dateKeyOf(dateOfKey(today).subtract(const Duration(days: 1))) ? p.dailyStreak + 1 : 1);
        p = p.copyWith(
          daily: rec.copyWith(
            completed: true,
            bestScore: r.score > rec.bestScore ? r.score : rec.bestScore,
            bestMoves: rec.bestMoves == 0 || r.moves < rec.bestMoves ? r.moves : rec.bestMoves,
          ),
          dailyStreak: streak,
          lastDailyCompleted: today,
        );
        if (first) {
          inc(AchievementMetric.dailyCompleted);
          stats[AchievementMetric.dailyStreak] = streak > (stats[AchievementMetric.dailyStreak] ?? 0) ? streak : stats[AchievementMetric.dailyStreak]!;
          analytics.log(AnalyticsEvent.dailyCompleted, {'streak': streak});
        }
      case GameMode.endless:
        p = p.copyWith(endlessIndex: endlessIndex + 1, endlessBest: endlessIndex + 1 > p.endlessBest ? endlessIndex + 1 : p.endlessBest);
      case GameMode.timeAttack:
        if (r.score > p.timeAttackBest) p = p.copyWith(timeAttackBest: r.score);
      case GameMode.perfect:
        if (r.score > p.perfectBest) p = p.copyWith(perfectBest: r.score);
    }

    inc(AchievementMetric.levelsCompleted);
    inc(AchievementMetric.tubesCompleted, tubesCompleted);
    if (r.perfect) inc(AchievementMetric.perfectLevels);
    if (!r.usedUndo) inc(AchievementMetric.noUndoLevels);
    if (r.seconds < 60) inc(AchievementMetric.fastLevels);

    _p = p.copyWith(stats: stats, coins: p.coins + coins);
    _checkAchievements();
    _set(_p);
    return coins;
  }

  /// Daily challenge attempt bookkeeping.
  void recordDailyAttempt() {
    final today = todayKey();
    final rec = _p.daily.dateKey == today ? _p.daily : DailyChallengeRecord(dateKey: today);
    _set(_p.copyWith(daily: rec.copyWith(attempts: rec.attempts + 1)));
  }

  DailyChallengeRecord get todaysDaily {
    final today = todayKey();
    return _p.daily.dateKey == today ? _p.daily : DailyChallengeRecord(dateKey: today);
  }

  // -------------------------------------------------------- achievements

  int achievementProgress(Achievement a) => _p.stat(a.metric);

  void _checkAchievements() {
    final unlocked = {..._p.achievements};
    var bonus = 0;
    for (final a in Achievement.all) {
      if (unlocked.contains(a.id)) continue;
      if (_p.stat(a.metric) >= a.goal) {
        unlocked.add(a.id);
        bonus += a.reward;
        _unlocks.add(a);
        analytics.log(AnalyticsEvent.achievementUnlocked, {'id': a.id});
      }
    }
    if (bonus > 0 || unlocked.length != _p.achievements.length) {
      _p = _p.copyWith(achievements: unlocked, coins: _p.coins + bonus);
    }
  }

  // -------------------------------------------------------- daily reward

  /// Index (0–6) of today's claimable reward, or null if already claimed.
  int? get claimableRewardIndex {
    final today = todayKey();
    if (_p.dailyRewardLastClaim == today) return null;
    return _nextRewardIndex(today);
  }

  /// Day index the calendar should highlight.
  int get rewardCursor => claimableRewardIndex ?? (_p.dailyRewardDay - 1).clamp(0, 6);

  int _nextRewardIndex(int today) {
    final yesterday = dateKeyOf(dateOfKey(today).subtract(const Duration(days: 1)));
    final continuing = _p.dailyRewardLastClaim == yesterday;
    if (!continuing) return 0;
    return _p.dailyRewardDay % 7;
  }

  DailyReward? claimDailyReward() {
    final idx = claimableRewardIndex;
    if (idx == null) return null;
    final r = DailyReward.cycle[idx];
    var p = _p.copyWith(dailyRewardDay: idx + 1, dailyRewardLastClaim: todayKey());
    switch (r.kind) {
      case RewardKind.coins:
        p = p.copyWith(coins: p.coins + r.amount);
      case RewardKind.hint:
        p = p.copyWith(hints: p.hints + r.amount);
      case RewardKind.undo:
        p = p.copyWith(undos: p.undos + r.amount);
      case RewardKind.extraTube:
        p = p.copyWith(extraTubes: p.extraTubes + r.amount);
      case RewardKind.skin:
        p = p.owns(DailyReward.skinRewardId)
            ? p.copyWith(coins: p.coins + 300)
            : p.copyWith(owned: {...p.owned, DailyReward.skinRewardId});
      case RewardKind.premium:
        p = p.copyWith(coins: p.coins + r.amount, hints: p.hints + 2, extraTubes: p.extraTubes + 1, shuffles: p.shuffles + 1);
    }
    _set(p);
    return r;
  }

  // ---------------------------------------------------------------- misc

  void setRemoveAds(bool v) => _set(_p.copyWith(removeAds: v));

  Future<void> resetProgress() async {
    await _repo.reset();
    _set(PlayerProgress(firstLaunch: _p.firstLaunch));
  }

  @override
  void dispose() {
    _unlocks.close();
    super.dispose();
  }
}
