import '../models/achievement.dart';
import '../models/cosmetics.dart';
import '../models/daily_challenge.dart';
import '../models/player_progress.dart';

/// `flutter run --dart-define=SCREENSHOT_MODE=true` starts the game with
/// demo progress in memory (nothing is saved) and no ads, for store
/// screenshots. Release builds never set it.
const bool screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

/// A believable mid-campaign player: level 48, mostly 3-star history,
/// a few cosmetics, today's daily reward already claimed.
PlayerProgress screenshotProgress(DateTime now) {
  final stars = <int, int>{for (var l = 1; l <= 47; l++) l: (l % 9 == 4 || l % 13 == 7) ? 2 : 3};
  return PlayerProgress(
    currentLevel: 48,
    stars: stars,
    coins: 2480,
    hints: 5,
    undos: 12,
    extraTubes: 3,
    shuffles: 2,
    owned: {
      ...defaultOwnedItems,
      BallSkin.glass.id,
      BallSkin.neon.id,
      BallSkin.candy.id,
      ThemeId.ocean.id,
    },
    achievements: {'first_sort', 'levels_10', 'perfect_sorter'},
    stats: {AchievementMetric.levelsCompleted: 47, AchievementMetric.threeStarLevels: 40},
    dailyRewardDay: 4,
    dailyRewardLastClaim: dateKeyOf(now),
    dailyStreak: 6,
    endlessIndex: 23,
    endlessBest: 23,
    timeAttackBest: 4,
    perfectBest: 7,
    firstLaunch: now.subtract(const Duration(days: 20)).millisecondsSinceEpoch,
  );
}
