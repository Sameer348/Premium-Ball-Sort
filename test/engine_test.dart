import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/game/engine/ball_sort_engine.dart';
import 'package:sort_sphere/game/engine/game_state.dart';
import 'package:sort_sphere/models/difficulty.dart';
import 'package:sort_sphere/models/level_data.dart';

LevelData lvl(List<List<int>> t, {int cap = 4}) => LevelData(number: 1, tubes: t, capacity: cap, difficulty: Difficulty.tutorial, par: 10);

void main() {
  group('canMove', () {
    final e = BallSortEngine(lvl([[0, 1], [1], [], [0, 0, 0, 1]]));
    test('onto same color with space', () => expect(e.canMove(0, 1), isTrue));
    test('onto empty tube', () => expect(e.canMove(0, 2), isTrue));
    test('onto a full tube is illegal', () => expect(e.canMove(1, 3), isFalse));
    test('from empty tube is illegal', () => expect(e.canMove(2, 0), isFalse));
    test('to itself is illegal', () => expect(e.canMove(0, 0), isFalse));
    test('mismatched color is illegal', () {
      final e2 = BallSortEngine(lvl([[0], [1], []]));
      expect(e2.canMove(0, 1), isFalse);
    });
    test('full destination is illegal even with matching color', () {
      final e2 = BallSortEngine(lvl([[1], [1, 1, 1, 1]]));
      expect(e2.canMove(0, 1), isFalse);
    });
  });

  test('moveBall moves exactly the top ball and records history', () {
    final e = BallSortEngine(lvl([[0, 1], [1], []]));
    final r = e.moveBall(0, 1)!;
    expect(r.color, 1);
    expect(e.tube(0).balls, [0]);
    expect(e.tube(1).balls, [1, 1]);
    expect(e.moves, 1);
    expect(e.history.length, 1);
    expect(e.moveBall(0, 1), isNull, reason: 'illegal move returns null');
    expect(e.moves, 1);
  });

  test('undo restores tubes, move count and clears selection', () {
    final e = BallSortEngine(lvl([[0, 1], [1], []]));
    expect(e.moveBall(0, 1), isNotNull); // 1 onto 1
    expect(e.moveBall(0, 2), isNotNull); // 0 into empty
    e.selectTube(1);
    final r = e.undo()!;
    expect(r.move.to, 2);
    expect(e.tube(0).balls, [0]);
    expect(e.tube(2).balls, isEmpty);
    expect(e.moves, 1);
    expect(e.selected, isNull);
    e.undo();
    expect(e.tube(0).balls, [0, 1]);
    expect(e.tube(1).balls, [1]);
    expect(e.moves, 0);
    expect(e.undo(), isNull);
    expect(e.undosUsed, 2);
  });

  test('isSolved only when each non-empty tube is full and uniform', () {
    expect(BallSortEngine(lvl([[0, 0, 0, 0], [1, 1, 1, 1], []])).isSolved(), isTrue);
    expect(BallSortEngine(lvl([[0, 0, 0], [0, 1, 1, 1], [1]])).isSolved(), isFalse);
    expect(BallSortEngine(lvl([[0, 0], [0, 0], [1, 1, 1, 1]])).isSolved(), isFalse, reason: 'split color is not solved');
  });

  test('isStuck when no meaningful move remains', () {
    expect(BallSortEngine(lvl([[0, 1], [1, 0]], cap: 2)).isStuck(), isTrue);
    expect(BallSortEngine(lvl([[0, 1], [1, 0], []], cap: 2)).isStuck(), isFalse);
    // Only move is uniform → empty (a relabel): stuck.
    expect(BallSortEngine(lvl([[0, 1, 0], [1, 0, 1], [2, 2]], cap: 3)).isStuck(), isTrue);
  });

  test('selectTube: select, deselect, move, invalid, reselect', () {
    final e = BallSortEngine(lvl([[0, 1], [2, 0], [], [0, 0, 0, 0]]));
    expect(e.selectTube(2).kind, TapKind.invalid, reason: 'empty tube cannot be selected');
    expect(e.selectTube(3).kind, TapKind.invalid, reason: 'completed tube cannot be selected');
    expect(e.selectTube(0).kind, TapKind.selected);
    expect(e.selectTube(0).kind, TapKind.deselected);
    e.selectTube(0);
    expect(e.selectTube(1).kind, TapKind.reselected);
    expect(e.selected, 1);
    final m = e.selectTube(2);
    expect(m.kind, TapKind.moved);
    expect(e.tube(2).balls, [0]);
    expect(e.state.status, isNot(GameStatus.solved));
  });

  test('addTube appends an empty tube up to the limit', () {
    final e = BallSortEngine(lvl([[0, 1], [1, 0]], cap: 2));
    expect(e.isStuck(), isTrue);
    expect(e.addTube(maxExtra: 1), isTrue);
    expect(e.tubeCount, 3);
    expect(e.isStuck(), isFalse);
    expect(e.addTube(maxExtra: 1), isFalse);
  });

  test('restart restores the original level', () {
    final e = BallSortEngine(lvl([[0, 1], [1], []]));
    e.moveBall(0, 1);
    e.addTube();
    e.restart();
    expect(e.tubeCount, 3);
    expect(e.tube(0).balls, [0, 1]);
    expect(e.moves, 0);
    expect(e.canUndo, isFalse);
  });
}
