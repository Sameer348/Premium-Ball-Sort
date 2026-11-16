import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/game/levels/handcrafted_levels.dart';
import 'package:sort_sphere/game/solver/ball_sort_solver.dart';
import 'package:sort_sphere/models/difficulty.dart';

void main() {
  final solver = BallSortSolver(maxNodes: 300000, weight: 1);

  test('there are 50 curated levels numbered 1..50', () {
    expect(handcraftedLevels.length, 50);
    for (var i = 0; i < 50; i++) {
      expect(handcraftedLevels[i].number, i + 1);
    }
  });

  test('every curated level is solvable within its par', () {
    for (final l in handcraftedLevels) {
      final r = solver.findSolution(l.tubes, l.capacity);
      expect(r.solved, isTrue, reason: 'level ${l.number}');
      expect(r.path!.length, lessThanOrEqualTo(l.par), reason: 'par must be achievable on level ${l.number}');
    }
  });

  test('difficulty bands follow the campaign plan', () {
    Difficulty d(int n) => handcraftedLevels[n - 1].difficulty;
    expect(d(1), Difficulty.tutorial);
    expect(d(10), Difficulty.tutorial);
    expect(d(11), Difficulty.easy);
    expect(d(25), Difficulty.medium);
    expect(d(35), Difficulty.hard);
    expect(d(50), Difficulty.expert);
    expect(handcraftedLevels[49].colorCount, greaterThan(handcraftedLevels[10].colorCount));
  });
}
