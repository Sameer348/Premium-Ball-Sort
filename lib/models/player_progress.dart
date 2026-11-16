import 'achievement.dart';
import 'cosmetics.dart';
import 'daily_challenge.dart';

/// Everything persisted about the player. Immutable; controllers produce
/// updated copies and hand them to the repository.
class PlayerProgress {
  PlayerProgress({
    this.currentLevel = 1,
    Map<int, int>? stars,
    Map<int, int>? bestMoves,
    Map<int, int>? bestScores,
    this.coins = 200,
    this.hints = 3,
    this.undos = 10,
    this.extraTubes = 2,
    this.shuffles = 1,
    Set<String>? owned,
    this.ballSkin = BallSkin.classic,
    this.tubeSkin = TubeSkin.classicGlass,
    this.theme = ThemeId.midnight,
    Set<String>? achievements,
    Map<AchievementMetric, int>? stats,
    this.dailyRewardDay = 0,
    this.dailyRewardLastClaim = 0,
    this.dailyStreak = 0,
    this.lastDailyCompleted = 0,
    DailyChallengeRecord? daily,
    this.endlessIndex = 0,
    this.endlessBest = 0,
    this.timeAttackBest = 0,
    this.perfectBest = 0,
    this.removeAds = false,
    this.firstLaunch = 0,
  })  : stars = stars ?? {},
        bestMoves = bestMoves ?? {},
        bestScores = bestScores ?? {},
        owned = owned ?? {...defaultOwnedItems},
        achievements = achievements ?? {},
        stats = stats ?? {},
        daily = daily ?? const DailyChallengeRecord(dateKey: 0);

  final int currentLevel;
  final Map<int, int> stars;
  final Map<int, int> bestMoves;
  final Map<int, int> bestScores;
  final int coins;
  final int hints;
  final int undos;
  final int extraTubes;
  final int shuffles;
  final Set<String> owned;
  final BallSkin ballSkin;
  final TubeSkin tubeSkin;
  final ThemeId theme;
  final Set<String> achievements;
  final Map<AchievementMetric, int> stats;

  /// Days of the 7-day cycle already claimed in the current streak (0–7).
  final int dailyRewardDay;

  /// yyyymmdd of the last daily-reward claim.
  final int dailyRewardLastClaim;
  final int dailyStreak;
  final int lastDailyCompleted;
  final DailyChallengeRecord daily;
  final int endlessIndex;
  final int endlessBest;
  final int timeAttackBest;
  final int perfectBest;

  /// Entitlement flag for a future "Remove Ads" purchase.
  final bool removeAds;

  /// Epoch ms of first launch.
  final int firstLaunch;

  int get totalStars => stars.values.fold(0, (a, b) => a + b);
  int get completedLevels => stars.length;
  int stat(AchievementMetric m) => stats[m] ?? 0;
  bool owns(String id) => owned.contains(id);

  PlayerProgress copyWith({
    int? currentLevel,
    Map<int, int>? stars,
    Map<int, int>? bestMoves,
    Map<int, int>? bestScores,
    int? coins,
    int? hints,
    int? undos,
    int? extraTubes,
    int? shuffles,
    Set<String>? owned,
    BallSkin? ballSkin,
    TubeSkin? tubeSkin,
    ThemeId? theme,
    Set<String>? achievements,
    Map<AchievementMetric, int>? stats,
    int? dailyRewardDay,
    int? dailyRewardLastClaim,
    int? dailyStreak,
    int? lastDailyCompleted,
    DailyChallengeRecord? daily,
    int? endlessIndex,
    int? endlessBest,
    int? timeAttackBest,
    int? perfectBest,
    bool? removeAds,
    int? firstLaunch,
  }) =>
      PlayerProgress(
        currentLevel: currentLevel ?? this.currentLevel,
        stars: stars ?? this.stars,
        bestMoves: bestMoves ?? this.bestMoves,
        bestScores: bestScores ?? this.bestScores,
        coins: coins ?? this.coins,
        hints: hints ?? this.hints,
        undos: undos ?? this.undos,
        extraTubes: extraTubes ?? this.extraTubes,
        shuffles: shuffles ?? this.shuffles,
        owned: owned ?? this.owned,
        ballSkin: ballSkin ?? this.ballSkin,
        tubeSkin: tubeSkin ?? this.tubeSkin,
        theme: theme ?? this.theme,
        achievements: achievements ?? this.achievements,
        stats: stats ?? this.stats,
        dailyRewardDay: dailyRewardDay ?? this.dailyRewardDay,
        dailyRewardLastClaim: dailyRewardLastClaim ?? this.dailyRewardLastClaim,
        dailyStreak: dailyStreak ?? this.dailyStreak,
        lastDailyCompleted: lastDailyCompleted ?? this.lastDailyCompleted,
        daily: daily ?? this.daily,
        endlessIndex: endlessIndex ?? this.endlessIndex,
        endlessBest: endlessBest ?? this.endlessBest,
        timeAttackBest: timeAttackBest ?? this.timeAttackBest,
        perfectBest: perfectBest ?? this.perfectBest,
        removeAds: removeAds ?? this.removeAds,
        firstLaunch: firstLaunch ?? this.firstLaunch,
      );

  static Map<String, int> _intMap(Map<int, int> m) => {for (final e in m.entries) '${e.key}': e.value};
  static Map<int, int> _readIntMap(Object? o) =>
      o is Map ? {for (final e in o.entries) int.parse(e.key as String): e.value as int} : {};

  Map<String, Object?> toJson() => {
        'v': 1,
        'level': currentLevel,
        'stars': _intMap(stars),
        'bestMoves': _intMap(bestMoves),
        'bestScores': _intMap(bestScores),
        'coins': coins,
        'hints': hints,
        'undos': undos,
        'extraTubes': extraTubes,
        'shuffles': shuffles,
        'owned': owned.toList(),
        'ballSkin': ballSkin.name,
        'tubeSkin': tubeSkin.name,
        'theme': theme.name,
        'achievements': achievements.toList(),
        'stats': {for (final e in stats.entries) e.key.name: e.value},
        'drDay': dailyRewardDay,
        'drLast': dailyRewardLastClaim,
        'streak': dailyStreak,
        'lastDaily': lastDailyCompleted,
        'daily': daily.toJson(),
        'endless': endlessIndex,
        'endlessBest': endlessBest,
        'taBest': timeAttackBest,
        'pfBest': perfectBest,
        'removeAds': removeAds,
        'firstLaunch': firstLaunch,
      };

  factory PlayerProgress.fromJson(Map<String, Object?> j) {
    T e<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    final statsJson = j['stats'];
    return PlayerProgress(
      currentLevel: j['level'] as int? ?? 1,
      stars: _readIntMap(j['stars']),
      bestMoves: _readIntMap(j['bestMoves']),
      bestScores: _readIntMap(j['bestScores']),
      coins: j['coins'] as int? ?? 200,
      hints: j['hints'] as int? ?? 3,
      undos: j['undos'] as int? ?? 10,
      extraTubes: j['extraTubes'] as int? ?? 2,
      shuffles: j['shuffles'] as int? ?? 1,
      owned: {...defaultOwnedItems, ...((j['owned'] as List?)?.cast<String>() ?? const [])},
      ballSkin: e(BallSkin.values, j['ballSkin'], BallSkin.classic),
      tubeSkin: e(TubeSkin.values, j['tubeSkin'], TubeSkin.classicGlass),
      theme: e(ThemeId.values, j['theme'], ThemeId.midnight),
      achievements: {...((j['achievements'] as List?)?.cast<String>() ?? const [])},
      stats: statsJson is Map
          ? {
              for (final m in AchievementMetric.values)
                if (statsJson[m.name] is int) m: statsJson[m.name] as int,
            }
          : {},
      dailyRewardDay: j['drDay'] as int? ?? 0,
      dailyRewardLastClaim: j['drLast'] as int? ?? 0,
      dailyStreak: j['streak'] as int? ?? 0,
      lastDailyCompleted: j['lastDaily'] as int? ?? 0,
      daily: j['daily'] is Map
          ? DailyChallengeRecord.fromJson((j['daily'] as Map).cast<String, Object?>())
          : const DailyChallengeRecord(dateKey: 0),
      endlessIndex: j['endless'] as int? ?? 0,
      endlessBest: j['endlessBest'] as int? ?? 0,
      timeAttackBest: j['taBest'] as int? ?? 0,
      perfectBest: j['pfBest'] as int? ?? 0,
      removeAds: j['removeAds'] as bool? ?? false,
      firstLaunch: j['firstLaunch'] as int? ?? 0,
    );
  }
}
