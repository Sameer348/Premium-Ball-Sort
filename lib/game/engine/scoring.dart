import 'dart:math' as math;

/// Result summary of a solved puzzle.
class LevelResult {
  const LevelResult({
    required this.stars,
    required this.score,
    required this.coins,
    required this.moves,
    required this.par,
    required this.seconds,
    required this.usedUndo,
    required this.usedHint,
    required this.perfect,
  });

  final int stars;
  final int score;
  final int coins;
  final int moves;
  final int par;
  final int seconds;
  final bool usedUndo;
  final bool usedHint;
  final bool perfect;
}

/// Friendly scoring: finishing always earns ≥1 star; efficiency and clean
/// play earn more, but boosters never take stars away.
class Scoring {
  const Scoring._();

  static int stars({required int moves, required int par}) {
    if (moves <= par) return 3;
    if (moves <= (par * 1.35).ceil()) return 2;
    return 1;
  }

  static int score({
    required int moves,
    required int par,
    required int colors,
    required bool usedUndo,
    required bool usedHint,
    int timeBonusSeconds = 0,
  }) {
    final base = 400 + colors * 120;
    final efficiency = math.max(0, (par * 1.6).round() - moves) * 25;
    final clean = (usedUndo ? 0 : 150) + (usedHint ? 0 : 100);
    return base + efficiency + clean + timeBonusSeconds * 10;
  }

  static int coins({required int stars, required bool firstClear, double multiplier = 1}) {
    final base = 10 + stars * 5;
    return ((firstClear ? base : (base / 2).ceil()) * multiplier).round();
  }

  static LevelResult evaluate({
    required int moves,
    required int par,
    required int colors,
    required int seconds,
    required bool usedUndo,
    required bool usedHint,
    required bool firstClear,
    double coinMultiplier = 1,
    int timeBonusSeconds = 0,
  }) {
    final s = stars(moves: moves, par: par);
    return LevelResult(
      stars: s,
      score: score(moves: moves, par: par, colors: colors, usedUndo: usedUndo, usedHint: usedHint, timeBonusSeconds: timeBonusSeconds),
      coins: coins(stars: s, firstClear: firstClear, multiplier: coinMultiplier),
      moves: moves,
      par: par,
      seconds: seconds,
      usedUndo: usedUndo,
      usedHint: usedHint,
      perfect: moves <= par,
    );
  }
}
