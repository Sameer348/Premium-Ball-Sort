import 'dart:isolate';

import '../../core/utils/seeded_random.dart';
import '../engine/move.dart';
import 'ball_sort_solver.dart';

enum HintStatus { found, alreadySolved, unsolvable, unknown }

class HintResult {
  const HintResult(this.status, [this.move]);
  final HintStatus status;
  final Move? move;
}

/// Runs the solver off the UI thread so hints never cause a frame drop.
/// Tries an optimal-ish search first, then a faster greedy one.
Future<HintResult> computeHint(List<List<int>> tubes, int capacity) async {
  try {
    final r = await Isolate.run(() => _hint(tubes, capacity));
    if (r[0] == 0) return HintResult(HintStatus.found, Move(r[1], r[2]));
    return HintResult(HintStatus.values[r[0]]);
  } on Object {
    return const HintResult(HintStatus.unknown);
  }
}

List<int> _hint(List<List<int>> tubes, int capacity) {
  if (BallSortSolver.isSolved(tubes, capacity)) return [1, 0, 0];
  for (final s in [BallSortSolver(maxNodes: 60000, weight: 1), BallSortSolver(maxNodes: 250000, weight: 4)]) {
    final r = s.findSolution(tubes, capacity);
    final p = r.path;
    if (p != null && p.isNotEmpty) return [0, p.first.from, p.first.to];
    if (r.provenUnsolvable) return [2, 0, 0];
  }
  return [3, 0, 0];
}

/// Shuffle booster: redistributes balls of unfinished tubes, keeping tube
/// sizes, and only returns a layout the solver proves solvable.
Future<List<List<int>>?> computeShuffle(List<List<int>> tubes, int capacity, int seed) async {
  try {
    return await Isolate.run(() => _shuffle(tubes, capacity, seed));
  } on Object {
    return null;
  }
}

List<List<int>>? _shuffle(List<List<int>> tubes, int capacity, int seed) {
  final rng = SeededRandom(seed);
  final solver = BallSortSolver(maxNodes: 60000, weight: 2);
  final open = <int>[];
  final pool = <int>[];
  for (var i = 0; i < tubes.length; i++) {
    final t = tubes[i];
    final done = t.length == capacity && t.every((b) => b == t.first);
    if (t.isEmpty || done) continue;
    open.add(i);
    pool.addAll(t);
  }
  if (open.isEmpty) return null;
  for (var attempt = 0; attempt < 40; attempt++) {
    final p = List<int>.from(pool);
    rng.shuffle(p);
    final out = [for (final t in tubes) List<int>.from(t)];
    var k = 0;
    for (final i in open) {
      final len = tubes[i].length;
      out[i] = p.sublist(k, k + len);
      k += len;
    }
    if (solver.findSolution(out, capacity).solved) return out;
  }
  return null;
}
