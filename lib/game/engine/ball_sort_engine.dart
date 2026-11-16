import '../../models/level_data.dart';
import 'game_state.dart';
import 'move.dart';
import 'tube_state.dart';

/// Result of tapping a tube.
enum TapKind { selected, deselected, reselected, moved, invalid, ignored }

class TapResult {
  const TapResult(this.kind, {this.tube, this.record, this.previous});
  final TapKind kind;

  /// Tube that was tapped.
  final int? tube;

  /// Previously selected tube (for reselect / invalid).
  final int? previous;

  /// The move that was executed, for [TapKind.moved].
  final MoveRecord? record;
}

/// Pure-Dart ball sort rules. Has no Flutter dependency so it can be unit
/// tested and reused by the solver, generator and any future server.
class BallSortEngine {
  BallSortEngine(this.level) {
    restart();
  }

  final LevelData level;
  late List<TubeState> _tubes;
  final List<MoveRecord> _history = [];
  int? _selected;
  int _moves = 0;
  int _undosUsed = 0;
  int _extraTubes = 0;

  int get capacity => level.capacity;
  List<TubeState> get tubes => List.unmodifiable(_tubes);
  TubeState tube(int i) => _tubes[i];
  int get tubeCount => _tubes.length;
  int? get selected => _selected;
  int get moves => _moves;
  int get undosUsed => _undosUsed;
  int get extraTubesAdded => _extraTubes;
  bool get canUndo => _history.isNotEmpty;
  List<MoveRecord> get history => List.unmodifiable(_history);

  GameStatus get status => isSolved()
      ? GameStatus.solved
      : isStuck()
          ? GameStatus.stuck
          : GameStatus.playing;

  GameState get state => GameState(
        tubes: tubes,
        selected: _selected,
        history: history,
        moves: _moves,
        status: status,
        undosUsed: _undosUsed,
        extraTubesAdded: _extraTubes,
      );

  /// Raw tube contents (copy), for the solver.
  List<List<int>> snapshot() => [for (final t in _tubes) List<int>.from(t.balls)];

  void restart() {
    _tubes = [for (final t in level.tubes) TubeState(t, level.capacity)];
    _history.clear();
    _selected = null;
    _moves = 0;
    _undosUsed = 0;
    _extraTubes = 0;
  }

  /// Tap handling: select a source, then a destination.
  TapResult selectTube(int index) {
    if (index < 0 || index >= _tubes.length || isSolved()) {
      return const TapResult(TapKind.ignored);
    }
    final sel = _selected;
    if (sel == null) {
      final t = _tubes[index];
      if (t.isEmpty || t.isComplete) return TapResult(TapKind.invalid, tube: index);
      _selected = index;
      return TapResult(TapKind.selected, tube: index);
    }
    if (sel == index) {
      _selected = null;
      return TapResult(TapKind.deselected, tube: index);
    }
    if (canMove(sel, index)) {
      final rec = moveBall(sel, index)!;
      return TapResult(TapKind.moved, tube: index, record: rec, previous: sel);
    }
    // Tapping another movable tube switches the selection.
    final t = _tubes[index];
    if (!t.isEmpty && !t.isComplete && _tubes[index].top != _tubes[sel].top) {
      _selected = index;
      return TapResult(TapKind.reselected, tube: index, previous: sel);
    }
    return TapResult(TapKind.invalid, tube: index, previous: sel);
  }

  void clearSelection() => _selected = null;

  bool canMove(int from, int to) {
    if (from == to) return false;
    if (from < 0 || to < 0 || from >= _tubes.length || to >= _tubes.length) return false;
    final src = _tubes[from];
    final dst = _tubes[to];
    if (src.isEmpty) return false;
    return dst.accepts(src.top!);
  }

  /// Moves the top ball of [from] onto [to]. Returns null when illegal.
  MoveRecord? moveBall(int from, int to) {
    if (!canMove(from, to)) return null;
    final color = _tubes[from].top!;
    final before = _selected;
    _tubes[from] = _tubes[from].pop();
    _tubes[to] = _tubes[to].push(color);
    final rec = MoveRecord(
      move: Move(from, to),
      color: color,
      movesBefore: _moves,
      selectedBefore: before,
      completedTube: _tubes[to].isComplete,
    );
    _history.add(rec);
    _moves++;
    _selected = null;
    return rec;
  }

  /// Reverts the last move. Returns the reverted record, or null.
  MoveRecord? undo() {
    if (_history.isEmpty) return null;
    final rec = _history.removeLast();
    final color = _tubes[rec.move.to].top!;
    _tubes[rec.move.to] = _tubes[rec.move.to].pop();
    _tubes[rec.move.from] = _tubes[rec.move.from].push(color);
    _moves = rec.movesBefore;
    _selected = null;
    _undosUsed++;
    return rec;
  }

  bool isSolved() {
    for (final t in _tubes) {
      if (!t.isEmpty && !t.isComplete) return false;
    }
    return true;
  }

  /// No meaningful move is left (moving a single-colored stack into an
  /// empty tube only relabels tubes, so it does not count).
  bool isStuck() {
    if (isSolved()) return false;
    for (var i = 0; i < _tubes.length; i++) {
      final src = _tubes[i];
      if (src.isEmpty || src.isComplete) continue;
      for (var j = 0; j < _tubes.length; j++) {
        if (i == j) continue;
        final dst = _tubes[j];
        if (!dst.accepts(src.top!)) continue;
        if (dst.isEmpty && src.isUniform) continue;
        return false;
      }
    }
    return true;
  }

  /// Appends an empty tube (booster). History stays valid since existing
  /// indices are unchanged.
  bool addTube({int maxExtra = 2}) {
    if (_extraTubes >= maxExtra) return false;
    _tubes.add(TubeState(const [], capacity));
    _extraTubes++;
    _selected = null;
    return true;
  }

  /// Replaces the board (shuffle booster). Clears history.
  void replaceTubes(List<List<int>> tubes) {
    _tubes = [for (final t in tubes) TubeState(t, capacity)];
    _history.clear();
    _selected = null;
  }
}
