// ignore_for_file: avoid_print
import 'package:sort_sphere/game/generator/ball_sort_level_generator.dart';
import 'package:sort_sphere/game/solver/ball_sort_solver.dart';
import 'package:sort_sphere/models/difficulty.dart';

void main(List<String> args) {
  for (final w in [1, 2]) {
    final gen = BallSortLevelGenerator(solver: BallSortSolver(maxNodes: 60000, weight: w));
    for (final d in Difficulty.values.skip(5)) {
      for (final empty in [2]) {
        final sw = Stopwatch()..start();
        final scores = <String>[];
        for (var s = 1; s <= 5; s++) {
          final l = gen.generate(GeneratorConfig(difficulty: d, seed: s * 7919, emptyTubes: empty));
          scores.add('${l.score}/${l.par}${l.emptyTubes == empty ? '' : '!'}');
        }
        print('w$w e$empty ${d.name.padRight(9)} ${sw.elapsedMilliseconds ~/ 5}ms  ${scores.join(' ')}');
      }
    }
  }
}
