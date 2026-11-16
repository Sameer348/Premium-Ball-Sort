/// Difficulty tiers. Each tier defines the *shape* of a puzzle; the
/// generator then picks, among solvable candidates, the one whose measured
/// difficulty (solution length, branching, forced moves, deadlock risk)
/// best fits the tier.
enum Difficulty {
  tutorial('Tutorial', colors: 3, emptyTubes: 2, maxRun: 2, target: 14),
  easy('Easy', colors: 4, emptyTubes: 2, maxRun: 2, target: 26),
  normal('Normal', colors: 4, emptyTubes: 2, maxRun: 1, target: 30),
  medium('Medium', colors: 5, emptyTubes: 2, maxRun: 2, target: 35),
  hard('Hard', colors: 6, emptyTubes: 2, maxRun: 1, target: 44),
  expert('Expert', colors: 7, emptyTubes: 2, maxRun: 1, target: 52),
  master('Master', colors: 8, emptyTubes: 2, maxRun: 1, target: 60),
  insane('Insane', colors: 10, emptyTubes: 2, maxRun: 1, target: 74);

  const Difficulty(
    this.label, {
    required this.colors,
    required this.emptyTubes,
    required this.maxRun,
    required this.target,
  });

  final String label;

  /// Default number of colors for this tier.
  final int colors;

  /// Default number of empty tubes.
  final int emptyTubes;

  /// Longest run of identical adjacent balls allowed in the starting layout.
  final int maxRun;

  /// Target difficulty score (see `DifficultyAnalyzer`).
  final int target;

  int get tubes => colors + emptyTubes;

  static Difficulty fromName(String name) =>
      Difficulty.values.firstWhere((d) => d.name == name, orElse: () => Difficulty.easy);

  /// Classifies a measured score into the closest tier.
  static Difficulty classify(int score) {
    var best = Difficulty.tutorial;
    var bestDist = 1 << 30;
    for (final d in Difficulty.values) {
      final dist = (d.target - score).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = d;
      }
    }
    return best;
  }
}
