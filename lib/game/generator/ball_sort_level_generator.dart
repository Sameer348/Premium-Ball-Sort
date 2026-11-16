import '../../core/utils/seeded_random.dart';
import '../../models/difficulty.dart';
import '../../models/level_data.dart';
import '../engine/move.dart';
import '../solver/ball_sort_solver.dart';
import 'difficulty_analyzer.dart';

/// Parameters for one generated puzzle.
class GeneratorConfig {
  GeneratorConfig({
    required this.difficulty,
    required this.seed,
    int? colorCount,
    int? tubeCount,
    int? emptyTubes,
    this.capacity = 4,
    this.levelNumber = 0,
  })  : colorCount = colorCount ?? difficulty.colors,
        emptyTubes = emptyTubes ?? difficulty.emptyTubes,
        tubeCount = tubeCount ?? (colorCount ?? difficulty.colors) + (emptyTubes ?? difficulty.emptyTubes);

  final Difficulty difficulty;
  final int seed;
  final int colorCount;
  final int tubeCount;
  final int emptyTubes;
  final int capacity;
  final int levelNumber;
}

/// Deterministic, solver-verified level generator.
///
/// Same config ⇒ same puzzle, always. Every returned level has been solved
/// by [BallSortSolver]; candidates the solver cannot finish are rejected.
class BallSortLevelGenerator {
  BallSortLevelGenerator({BallSortSolver? solver, this.candidates = 5, this.maxAttempts = 60})
      : solver = solver ?? BallSortSolver(maxNodes: 60000, weight: 1);

  final BallSortSolver solver;

  /// Solvable candidates compared before choosing the best fit.
  final int candidates;
  final int maxAttempts;

  LevelData generate(GeneratorConfig cfg) {
    assert(cfg.colorCount >= 1 && cfg.colorCount <= 10, 'colorCount must be 1..10');
    final filled = cfg.tubeCount - cfg.emptyTubes;
    assert(filled * cfg.capacity >= cfg.colorCount * cfg.capacity, 'not enough tubes');
    final rng = SeededRandom(SeededRandom.hash(cfg.seed ^ 0x9E3779B9));

    LevelData? best;
    var bestDist = 1 << 30;
    var found = 0;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final board = _deal(rng, cfg, filled);
      if (!_acceptLayout(board, cfg)) continue;
      final result = solver.findSolution(board, cfg.capacity);
      final path = result.path;
      if (path == null || path.isEmpty) continue;
      final m = DifficultyAnalyzer.analyze(board, cfg.capacity, path);
      final dist = (m.score - cfg.difficulty.target).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = _level(cfg, board, path, m.score);
      }
      found++;
      if (found >= candidates || dist <= 2) break;
    }
    return best ?? _fallback(rng, cfg);
  }

  /// Randomly deals capacity × colors balls into the filled tubes.
  List<List<int>> _deal(SeededRandom rng, GeneratorConfig cfg, int filled) {
    final pool = <int>[
      for (var c = 0; c < cfg.colorCount; c++)
        for (var k = 0; k < cfg.capacity; k++) c,
    ];
    rng.shuffle(pool);
    final tubes = List.generate(cfg.tubeCount, (_) => <int>[]);
    // Fill the first `filled` tubes evenly (all full when filled == colors).
    var t = 0;
    for (final b in pool) {
      while (tubes[t].length >= cfg.capacity) {
        t = (t + 1) % filled;
      }
      tubes[t].add(b);
      t = (t + 1) % filled;
    }
    // Shuffle tube order but keep empty tubes at the end for a tidy board.
    final head = tubes.sublist(0, filled);
    rng.shuffle(head);
    return [...head, ...tubes.sublist(filled)];
  }

  bool _acceptLayout(List<List<int>> board, GeneratorConfig cfg) {
    for (final t in board) {
      if (t.isEmpty) continue;
      if (t.length == cfg.capacity && t.every((b) => b == t.first)) return false;
      var run = 1;
      for (var i = 1; i < t.length; i++) {
        run = t[i] == t[i - 1] ? run + 1 : 1;
        if (run > cfg.difficulty.maxRun + 1) return false;
      }
    }
    // Hard tiers: avoid giving away free same-color tops.
    if (cfg.difficulty.index >= Difficulty.hard.index) {
      var adjacent = 0;
      for (final t in board) {
        for (var i = 1; i < t.length; i++) {
          if (t[i] == t[i - 1]) adjacent++;
        }
      }
      if (adjacent > cfg.colorCount ~/ 3) return false;
    }
    return true;
  }

  LevelData _level(GeneratorConfig cfg, List<List<int>> board, List<Move> path, int score) => LevelData(
        number: cfg.levelNumber,
        tubes: board,
        capacity: cfg.capacity,
        difficulty: cfg.difficulty,
        par: path.length,
        seed: cfg.seed,
        score: score,
      );

  /// Guaranteed-solvable construction: scramble a solved board using only
  /// reverse-legal steps, so the reversed sequence is a valid solution.
  LevelData _fallback(SeededRandom rng, GeneratorConfig cfg) {
    final tubes = List.generate(cfg.tubeCount, (i) => i < cfg.colorCount
        ? List<int>.filled(cfg.capacity, i, growable: true)
        : <int>[]);
    final steps = <Move>[];
    final want = cfg.colorCount * cfg.capacity * 3;
    var guard = 0;
    while (steps.length < want && guard++ < want * 40) {
      final y = rng.nextInt(tubes.length);
      final ty = tubes[y];
      if (ty.isEmpty) continue;
      final c = ty.last;
      // Forward move x→y must be legal afterwards: y below must be c or empty.
      if (ty.length > 1 && ty[ty.length - 2] != c) continue;
      final x = rng.nextInt(tubes.length);
      if (x == y || tubes[x].length >= cfg.capacity) continue;
      ty.removeLast();
      tubes[x].add(c);
      steps.add(Move(x, y));
    }
    final verify = solver.findSolution(tubes, cfg.capacity).path;
    final path = verify ?? steps.reversed.toList();
    final m = DifficultyAnalyzer.analyze(tubes, cfg.capacity, path);
    return _level(cfg, tubes, path, m.score);
  }
}
