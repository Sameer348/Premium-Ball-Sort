import '../../core/utils/seeded_random.dart';
import '../../models/difficulty.dart';
import '../../models/level_data.dart';
import '../generator/ball_sort_level_generator.dart';
import 'handcrafted_levels.dart';

/// Source of every campaign level.
///
/// Levels 1–50 are curated and stored verbatim ([handcraftedLevels]).
/// From 51 on, levels are produced on demand by the deterministic generator
/// from a seed derived from the level number, so 1000+ levels cost no
/// storage and are identical on every device.
class LevelCatalog {
  LevelCatalog._();

  static const int handcraftedCount = 50;

  /// Campaign size shown on the map. Generation itself is unbounded.
  static const int totalLevels = 2000;

  static int seedFor(int level) => SeededRandom.hash(level * 2654435761 + 0x5EED);

  static Difficulty difficultyFor(int level) {
    if (level <= 10) return Difficulty.tutorial;
    if (level <= 20) return Difficulty.easy;
    if (level <= 30) return Difficulty.medium;
    if (level <= 40) return Difficulty.hard;
    if (level <= 50) return Difficulty.expert;
    // Rhythm: mostly hard, regular breathers so the curve never feels like
    // a wall.
    if (level % 10 == 0) {
      return level <= 300 ? Difficulty.medium : Difficulty.hard;
    }
    if (level <= 100) return level % 5 == 0 ? Difficulty.expert : Difficulty.master;
    if (level <= 300) return level.isOdd ? Difficulty.master : Difficulty.insane;
    return level % 4 == 0 ? Difficulty.master : Difficulty.insane;
  }

  static GeneratorConfig configFor(int level) {
    final d = difficultyFor(level);
    var colors = d.colors;
    if (d == Difficulty.master && level.isOdd) colors = 9;
    return GeneratorConfig(difficulty: d, seed: seedFor(level), colorCount: colors, levelNumber: level);
  }

  /// Synchronous lookup. For level > 50 this runs the generator (a few
  /// milliseconds to ~50 ms); call it via `compute` from UI code.
  static LevelData level(int number) {
    if (number >= 1 && number <= handcraftedLevels.length) {
      return handcraftedLevels[number - 1];
    }
    return BallSortLevelGenerator().generate(configFor(number));
  }

  /// Daily puzzle: date → seed, weekday → difficulty (gentle Monday,
  /// demanding weekend).
  static LevelData daily(DateTime date) {
    final key = date.year * 10000 + date.month * 100 + date.day;
    const byWeekday = [
      Difficulty.medium, // Mon
      Difficulty.medium,
      Difficulty.hard,
      Difficulty.hard,
      Difficulty.expert,
      Difficulty.master,
      Difficulty.master, // Sun
    ];
    final d = byWeekday[date.weekday - 1];
    return BallSortLevelGenerator().generate(
      GeneratorConfig(difficulty: d, seed: SeededRandom.hash(key ^ 0xDA11)),
    );
  }

  /// Endless mode: index → ramping difficulty.
  static LevelData endless(int index) {
    final tiers = [Difficulty.easy, Difficulty.medium, Difficulty.hard, Difficulty.expert, Difficulty.master, Difficulty.insane];
    final d = tiers[(index ~/ 5).clamp(0, tiers.length - 1)];
    return BallSortLevelGenerator().generate(
      GeneratorConfig(difficulty: d, seed: SeededRandom.hash(index * 7919 + 0xE7D)),
    );
  }

  /// Time-attack / perfect-sort puzzles from a run seed.
  static LevelData special(int seed, Difficulty d) =>
      BallSortLevelGenerator().generate(GeneratorConfig(difficulty: d, seed: SeededRandom.hash(seed)));
}

/// Top-level helpers for `compute` (must be static/top-level).
LevelData generateCampaignLevel(int number) => LevelCatalog.level(number);
LevelData generateDailyLevel(int yyyymmdd) =>
    LevelCatalog.daily(DateTime(yyyymmdd ~/ 10000, yyyymmdd ~/ 100 % 100, yyyymmdd % 100));
LevelData generateEndlessLevel(int index) => LevelCatalog.endless(index);
LevelData generateSpecialLevel(List<int> args) =>
    LevelCatalog.special(args[0], Difficulty.values[args[1]]);
