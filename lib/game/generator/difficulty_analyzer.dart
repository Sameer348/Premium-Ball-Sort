import '../../models/difficulty.dart';
import '../engine/move.dart';
import '../solver/ball_sort_solver.dart';

/// Measured properties of a solved puzzle.
class DifficultyMetrics {
  const DifficultyMetrics({
    required this.colors,
    required this.tubes,
    required this.emptySlots,
    required this.solutionLength,
    required this.branching,
    required this.forcedMoves,
    required this.deadlockRisk,
    required this.score,
  });

  final int colors;
  final int tubes;
  final int emptySlots;
  final int solutionLength;

  /// Mean number of meaningful moves along the solution path.
  final double branching;

  /// Steps where at most two meaningful moves existed.
  final int forcedMoves;

  /// Fraction of available moves (along the path) that lead straight into a
  /// position with no meaningful move.
  final double deadlockRisk;

  /// Combined 0–100+ score.
  final int score;

  Difficulty get tier => Difficulty.classify(score);
}

class DifficultyAnalyzer {
  const DifficultyAnalyzer._();

  static DifficultyMetrics analyze(List<List<int>> start, int capacity, List<Move> solution) {
    final colors = {for (final t in start) ...t}.length;
    final emptySlots = start.fold<int>(0, (a, t) => a + capacity - t.length);
    var board = [for (final t in start) List<int>.from(t)];
    var branchSum = 0;
    var forced = 0;
    var risky = 0;
    var total = 0;
    for (final m in solution) {
      final moves = BallSortSolver.getAvailableMoves(board, capacity);
      branchSum += moves.length;
      if (moves.length <= 2) forced++;
      for (final alt in moves) {
        total++;
        final next = BallSortSolver.simulateMove(board, alt);
        if (!BallSortSolver.isSolved(next, capacity) &&
            BallSortSolver.getAvailableMoves(next, capacity).isEmpty) {
          risky++;
        }
      }
      board = BallSortSolver.simulateMove(board, m);
    }
    final len = solution.length;
    final branching = len == 0 ? 0.0 : branchSum / len;
    final risk = total == 0 ? 0.0 : risky / total;
    // Weighted blend: long solutions with few good options (low branching,
    // many forced steps) and traps are what make ball sort hard.
    final raw = len * 0.62 +
        colors * 3.2 +
        forced * 0.55 +
        risk * 60 -
        (emptySlots - 2 * capacity).clamp(0, 99) * 1.5 -
        (branching - 4).clamp(0, 99) * 0.8;
    return DifficultyMetrics(
      colors: colors,
      tubes: start.length,
      emptySlots: emptySlots,
      solutionLength: len,
      branching: branching,
      forcedMoves: forced,
      deadlockRisk: risk,
      score: raw.round().clamp(0, 999),
    );
  }
}
