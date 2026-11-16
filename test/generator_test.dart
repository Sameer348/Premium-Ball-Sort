import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/game/generator/ball_sort_level_generator.dart';
import 'package:sort_sphere/game/levels/level_catalog.dart';
import 'package:sort_sphere/game/solver/ball_sort_solver.dart';
import 'package:sort_sphere/models/difficulty.dart';

void main() {
  final gen = BallSortLevelGenerator();
  final verifier = BallSortSolver(maxNodes: 300000, weight: 2);

  void checkWellFormed(List<List<int>> tubes, int colors, int cap) {
    final counts = <int, int>{};
    for (final t in tubes) {
      expect(t.length, lessThanOrEqualTo(cap));
      for (final b in t) {
        counts[b] = (counts[b] ?? 0) + 1;
      }
    }
    expect(counts.length, colors);
    expect(counts.values.every((c) => c == cap), isTrue, reason: 'each color appears exactly capacity times');
  }

  test('same seed → identical puzzle', () {
    for (final d in Difficulty.values) {
      final a = gen.generate(GeneratorConfig(difficulty: d, seed: 42));
      final b = BallSortLevelGenerator().generate(GeneratorConfig(difficulty: d, seed: 42));
      expect(a.tubes, b.tubes, reason: d.name);
      expect(a.par, b.par);
    }
  });

  test('different seeds → different puzzles', () {
    final a = gen.generate(GeneratorConfig(difficulty: Difficulty.hard, seed: 1));
    final b = gen.generate(GeneratorConfig(difficulty: Difficulty.hard, seed: 2));
    expect(a.tubes, isNot(b.tubes));
  });

  test('every tier generates well-formed, solver-verified levels', () {
    for (final d in Difficulty.values) {
      for (var s = 0; s < 4; s++) {
        final l = gen.generate(GeneratorConfig(difficulty: d, seed: 1000 + s));
        checkWellFormed(l.tubes, d.colors, l.capacity);
        expect(l.tubeCount, d.tubes);
        expect(l.tubes.any((t) => t.length == l.capacity && t.every((b) => b == t.first)), isFalse, reason: 'no pre-solved tube');
        expect(verifier.findSolution(l.tubes, l.capacity).solved, isTrue, reason: '${d.name} seed $s');
        expect(l.par, greaterThan(0));
      }
    }
  });

  test('custom parameters are respected (capacity 5, 3 empties)', () {
    final l = gen.generate(GeneratorConfig(difficulty: Difficulty.medium, seed: 9, colorCount: 4, emptyTubes: 3, capacity: 5));
    expect(l.capacity, 5);
    expect(l.tubeCount, 7);
    checkWellFormed(l.tubes, 4, 5);
    expect(verifier.findSolution(l.tubes, 5).solved, isTrue);
  });

  test('procedural campaign levels 51–80 are deterministic and solvable', () {
    for (var n = 51; n <= 80; n++) {
      final a = LevelCatalog.level(n);
      expect(a.number, n);
      expect(LevelCatalog.level(n).tubes, a.tubes);
      expect(verifier.findSolution(a.tubes, a.capacity).solved, isTrue, reason: 'level $n');
    }
  });

  test('deep levels (500, 1000, 1999) generate and solve', () {
    for (final n in [500, 1000, 1999]) {
      final l = LevelCatalog.level(n);
      expect(verifier.findSolution(l.tubes, l.capacity).solved, isTrue, reason: 'level $n');
    }
  });

  test('daily puzzle is a pure function of the date', () {
    final d1 = LevelCatalog.daily(DateTime(2026, 11, 15));
    final d2 = LevelCatalog.daily(DateTime(2026, 11, 15, 23, 59));
    final d3 = LevelCatalog.daily(DateTime(2026, 11, 16));
    expect(d1.tubes, d2.tubes);
    expect(d1.tubes, isNot(d3.tubes));
    expect(verifier.findSolution(d1.tubes, d1.capacity).solved, isTrue);
  });
}
