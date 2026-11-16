import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/core/utils/seeded_random.dart';
import 'package:sort_sphere/game/engine/move.dart';
import 'package:sort_sphere/game/solver/ball_sort_solver.dart';

/// Independent, naive BFS over raw boards (no pruning, no codec) used to
/// cross-check the optimised solver.
bool naiveSolvable(List<List<int>> start, int cap) {
  String key(List<List<int>> b) => (b.map((t) => t.join(',')).toList()..sort()).join('|');
  final seen = HashSet<String>()..add(key(start));
  final q = Queue<List<List<int>>>()..add(start);
  while (q.isNotEmpty) {
    final b = q.removeFirst();
    if (BallSortSolver.isSolved(b, cap)) return true;
    for (var i = 0; i < b.length; i++) {
      if (b[i].isEmpty) continue;
      for (var j = 0; j < b.length; j++) {
        if (i == j || b[j].length >= cap) continue;
        if (b[j].isNotEmpty && b[j].last != b[i].last) continue;
        final n = BallSortSolver.simulateMove(b, Move(i, j));
        if (seen.add(key(n))) q.add(n);
      }
    }
  }
  return false;
}

List<List<int>> apply(List<List<int>> b, List<Move> path, int cap) {
  var cur = b;
  for (final m in path) {
    expect(cur[m.from], isNotEmpty);
    final ball = cur[m.from].last;
    expect(cur[m.to].length < cap && (cur[m.to].isEmpty || cur[m.to].last == ball), isTrue, reason: 'illegal move $m');
    cur = BallSortSolver.simulateMove(cur, m);
  }
  return cur;
}

void main() {
  final solver = BallSortSolver(maxNodes: 200000, weight: 1);

  test('simulateMove does not mutate input', () {
    final b = [[0, 1], <int>[]];
    final n = BallSortSolver.simulateMove(b, const Move(0, 1));
    expect(b, [[0, 1], <int>[]]);
    expect(n, [[0], [1]]);
  });

  test('getAvailableMoves prunes symmetric moves', () {
    final moves = BallSortSolver.getAvailableMoves([[0, 1], [1], [], []], 4);
    expect(moves, containsAll([const Move(0, 1), const Move(0, 2)]));
    expect(moves.contains(const Move(0, 3)), isFalse, reason: 'second empty tube is symmetric');
    expect(moves.contains(const Move(1, 2)), isFalse, reason: 'uniform stack into empty is a relabel');
    final all = BallSortSolver.getAvailableMoves([[0, 1], [1], [], []], 4, pruned: false);
    expect(all.length, greaterThan(moves.length));
  });

  test('finds a valid solution and reports solved', () {
    final b = [[0, 1, 2, 0], [1, 2, 0, 1], [2, 0, 1, 2], <int>[], <int>[]];
    final r = solver.findSolution(b, 4);
    expect(r.solved, isTrue);
    expect(BallSortSolver.isSolved(apply(b, r.path!, 4), 4), isTrue);
  });

  test('proves a dead position unsolvable', () {
    final b = [[0, 1], [1, 0]];
    final r = solver.findSolution(b, 2);
    expect(r.provenUnsolvable, isTrue);
    expect(solver.isDeadlocked(b, 2), isTrue);
  });

  test('already solved yields empty path and no hint', () {
    final b = [[0, 0], [1, 1], <int>[]];
    expect(solver.findSolution(b, 2).path, isEmpty);
    expect(solver.getHint(b, 2), isNull);
  });

  test('hint is the first step of a real solution', () {
    final b = [[0, 1, 0, 1], [1, 0, 1, 0], <int>[], <int>[]];
    final h = solver.getHint(b, 4)!;
    final after = BallSortSolver.simulateMove(b, h);
    expect(solver.findSolution(after, 4).solved, isTrue);
  });

  test('agrees with naive BFS on 300 random small boards', () {
    final rng = SeededRandom(1234);
    var solvable = 0;
    for (var k = 0; k < 300; k++) {
      const cap = 3;
      final colors = 2 + rng.nextInt(2);
      final empties = rng.nextInt(2) + (k.isEven ? 0 : 1);
      final pool = [for (var c = 0; c < colors; c++) for (var i = 0; i < cap; i++) c];
      rng.shuffle(pool);
      final b = <List<int>>[for (var c = 0; c < colors; c++) pool.sublist(c * cap, c * cap + cap), for (var e = 0; e < empties; e++) <int>[]];
      final expected = naiveSolvable(b, cap);
      final r = solver.findSolution(b, cap);
      expect(r.solved || r.exhausted, isTrue, reason: 'small boards must be decided');
      expect(r.solved, expected, reason: 'board $b');
      if (r.solved) {
        solvable++;
        expect(BallSortSolver.isSolved(apply(b, r.path!, cap), cap), isTrue);
      }
    }
    expect(solvable, greaterThan(50));
  });
}
