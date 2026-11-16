import 'difficulty.dart';

/// An immutable puzzle definition. Tubes are listed bottom → top and each
/// ball is a color index into the active ball palette.
class LevelData {
  const LevelData({
    required this.number,
    required this.tubes,
    required this.capacity,
    required this.difficulty,
    required this.par,
    this.seed = 0,
    this.score = 0,
  });

  /// Level number (1-based). 0 for non-campaign puzzles.
  final int number;
  final List<List<int>> tubes;
  final int capacity;
  final Difficulty difficulty;

  /// Target move count (a verified solver solution length).
  final int par;
  final int seed;

  /// Measured difficulty score.
  final int score;

  int get colorCount {
    final s = <int>{};
    for (final t in tubes) {
      s.addAll(t);
    }
    return s.length;
  }

  int get tubeCount => tubes.length;

  int get emptyTubes => tubes.where((t) => t.isEmpty).length;

  LevelData copyWith({int? number, Difficulty? difficulty}) => LevelData(
        number: number ?? this.number,
        tubes: tubes,
        capacity: capacity,
        difficulty: difficulty ?? this.difficulty,
        par: par,
        seed: seed,
        score: score,
      );

  Map<String, Object?> toJson() => {
        'n': number,
        't': tubes,
        'c': capacity,
        'd': difficulty.name,
        'p': par,
        's': seed,
        'x': score,
      };

  factory LevelData.fromJson(Map<String, Object?> j) => LevelData(
        number: j['n'] as int,
        tubes: [for (final t in j['t'] as List) List<int>.from(t as List)],
        capacity: j['c'] as int,
        difficulty: Difficulty.fromName(j['d'] as String),
        par: j['p'] as int,
        seed: (j['s'] as int?) ?? 0,
        score: (j['x'] as int?) ?? 0,
      );
}
