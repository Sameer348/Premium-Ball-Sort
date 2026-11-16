import 'dart:collection';
import 'dart:typed_data';

import '../engine/move.dart';
import 'tube_codec.dart';

/// Outcome of a search.
class SolverResult {
  const SolverResult({required this.path, required this.exhausted, required this.explored});

  /// Moves from the start state to a solved state, or null.
  final List<Move>? path;

  /// True when the whole reachable space was searched (so a null [path]
  /// *proves* the position is unsolvable).
  final bool exhausted;
  final int explored;

  bool get solved => path != null;
  bool get provenUnsolvable => path == null && exhausted;
}

/// Weighted-A* ball sort solver with canonical visited-state hashing.
///
/// * Tubes are interchangeable, so a state's key is its *sorted* tube codes —
///   permutations collapse into one node and loops are impossible.
/// * Moves that cannot change the canonical state (a single-colored stack
///   into an empty tube, a finished tube into an empty tube, a second empty
///   destination) are pruned, which keeps the "exhausted ⇒ unsolvable"
///   guarantee intact.
class BallSortSolver {
  BallSortSolver({this.maxNodes = 120000, this.weight = 3});

  /// Node budget before giving up (result is then "unknown").
  final int maxNodes;

  /// Heuristic weight. 1 = A* (shortest), higher = faster, slightly longer.
  final int weight;

  // ------------------------------------------------------------------ API

  /// Legal moves. With [pruned], symmetric no-op moves are skipped.
  static List<Move> getAvailableMoves(List<List<int>> tubes, int capacity, {bool pruned = true}) {
    final moves = <Move>[];
    for (var i = 0; i < tubes.length; i++) {
      final src = tubes[i];
      if (src.isEmpty) continue;
      final ball = src.last;
      final uniform = src.every((b) => b == ball);
      if (pruned && uniform && src.length == capacity) continue;
      var emptyUsed = false;
      for (var j = 0; j < tubes.length; j++) {
        if (i == j) continue;
        final dst = tubes[j];
        if (dst.length >= capacity) continue;
        if (dst.isEmpty) {
          if (pruned && (uniform || emptyUsed)) continue;
          emptyUsed = true;
          moves.add(Move(i, j));
        } else if (dst.last == ball) {
          moves.add(Move(i, j));
        }
      }
    }
    return moves;
  }

  /// Returns a new board with [move] applied (input untouched).
  static List<List<int>> simulateMove(List<List<int>> tubes, Move move) {
    final out = [for (final t in tubes) List<int>.from(t)];
    final ball = out[move.from].removeLast();
    out[move.to].add(ball);
    return out;
  }

  static bool isSolved(List<List<int>> tubes, int capacity) {
    for (final t in tubes) {
      if (t.isEmpty) continue;
      if (t.length != capacity) return false;
      for (final b in t) {
        if (b != t.first) return false;
      }
    }
    return true;
  }

  /// No meaningful move exists, or search proves no solution exists.
  bool isDeadlocked(List<List<int>> tubes, int capacity) {
    if (isSolved(tubes, capacity)) return false;
    if (getAvailableMoves(tubes, capacity).isEmpty) return true;
    return findSolution(tubes, capacity).provenUnsolvable;
  }

  /// The next move of a solution path from this exact position.
  Move? getHint(List<List<int>> tubes, int capacity) {
    final r = findSolution(tubes, capacity);
    final p = r.path;
    if (p == null || p.isEmpty) return null;
    return p.first;
  }

  SolverResult findSolution(List<List<int>> tubes, int capacity) {
    final codec = TubeCodec.of(capacity);
    final n = tubes.length;
    final start = Int32List(n);
    for (var i = 0; i < n; i++) {
      start[i] = codec.encode(tubes[i]);
    }
    if (_solved(codec, start)) {
      return const SolverResult(path: [], exhausted: true, explored: 0);
    }

    final states = <Int32List>[start];
    final parent = <int>[-1];
    final moveFrom = <int>[-1];
    final moveTo = <int>[-1];
    final g = <int>[0];
    final h = <int>[_heuristic(codec, start)];
    final visited = HashSet<String>()..add(_key(start));
    final heap = _Heap((a, b) {
      final fa = g[a] + weight * h[a];
      final fb = g[b] + weight * h[b];
      if (fa != fb) return fa - fb;
      return h[a] - h[b];
    })
      ..push(0);

    var explored = 0;
    while (heap.isNotEmpty) {
      final idx = heap.pop();
      explored++;
      if (explored > maxNodes) {
        return SolverResult(path: null, exhausted: false, explored: explored);
      }
      final s = states[idx];
      for (var i = 0; i < n; i++) {
        final sc = s[i];
        final slen = codec.length[sc];
        if (slen == 0) continue;
        final ball = codec.top[sc];
        final uniform = codec.isUniform(sc);
        if (uniform && slen == capacity) continue;
        var emptyUsed = false;
        for (var j = 0; j < n; j++) {
          if (i == j) continue;
          final dc = s[j];
          final dlen = codec.length[dc];
          if (dlen >= capacity) continue;
          if (dlen == 0) {
            if (uniform || emptyUsed) continue;
            emptyUsed = true;
          } else if (codec.top[dc] != ball) {
            continue;
          }
          final next = Int32List.fromList(s);
          next[i] = codec.pop(sc);
          next[j] = codec.push(dc, ball);
          final key = _key(next);
          if (!visited.add(key)) continue;
          final ni = states.length;
          states.add(next);
          parent.add(idx);
          moveFrom.add(i);
          moveTo.add(j);
          g.add(g[idx] + 1);
          final hn = _heuristic(codec, next);
          h.add(hn);
          if (hn == 0 && _solved(codec, next)) {
            return SolverResult(
              path: _path(ni, parent, moveFrom, moveTo),
              exhausted: false,
              explored: explored,
            );
          }
          heap.push(ni);
        }
      }
    }
    return SolverResult(path: null, exhausted: true, explored: explored);
  }

  // ------------------------------------------------------------ internals

  static List<Move> _path(int idx, List<int> parent, List<int> from, List<int> to) {
    final out = <Move>[];
    var i = idx;
    while (parent[i] >= 0) {
      out.add(Move(from[i], to[i]));
      i = parent[i];
    }
    return out.reversed.toList();
  }

  static bool _solved(TubeCodec c, Int32List s) {
    for (final code in s) {
      final len = c.length[code];
      if (len != 0 && !c.isComplete(code)) return false;
    }
    return true;
  }

  static String _key(Int32List s) {
    final sorted = Int32List.fromList(s)..sort();
    return String.fromCharCodes(sorted);
  }

  /// Lower-bound-ish estimate of remaining moves:
  /// every ball above a tube's bottom run must move at least once, and when a
  /// color forms a bottom run in several tubes all but the largest must move.
  static final _bestRun = Int32List(TubeCodec.maxColors);
  static final _sumRun = Int32List(TubeCodec.maxColors);

  static int _heuristic(TubeCodec c, Int32List s) {
    var hv = 0;
    for (var k = 0; k < TubeCodec.maxColors; k++) {
      _bestRun[k] = 0;
      _sumRun[k] = 0;
    }
    for (final code in s) {
      final len = c.length[code];
      if (len == 0) continue;
      final br = c.bottomRun[code];
      hv += len - br;
      final col = c.bottom[code];
      _sumRun[col] += br;
      if (br > _bestRun[col]) _bestRun[col] = br;
    }
    for (var k = 0; k < TubeCodec.maxColors; k++) {
      hv += _sumRun[k] - _bestRun[k];
    }
    return hv;
  }
}

/// Minimal binary heap of node indices.
class _Heap {
  _Heap(this.compare);
  final int Function(int a, int b) compare;
  final List<int> _d = [];

  bool get isNotEmpty => _d.isNotEmpty;

  void push(int v) {
    _d.add(v);
    var i = _d.length - 1;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (compare(_d[i], _d[p]) >= 0) break;
      final t = _d[i];
      _d[i] = _d[p];
      _d[p] = t;
      i = p;
    }
  }

  int pop() {
    final top = _d.first;
    final last = _d.removeLast();
    if (_d.isNotEmpty) {
      _d[0] = last;
      var i = 0;
      final n = _d.length;
      while (true) {
        final l = 2 * i + 1;
        final r = l + 1;
        var m = i;
        if (l < n && compare(_d[l], _d[m]) < 0) m = l;
        if (r < n && compare(_d[r], _d[m]) < 0) m = r;
        if (m == i) break;
        final t = _d[i];
        _d[i] = _d[m];
        _d[m] = t;
        i = m;
      }
    }
    return top;
  }
}
