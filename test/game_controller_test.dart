import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/features/gameplay/game_controller.dart';
import 'package:sort_sphere/game/levels/level_catalog.dart';
import 'package:sort_sphere/game/solver/ball_sort_solver.dart';
import 'package:sort_sphere/models/booster.dart';
import 'package:sort_sphere/models/game_mode.dart';
import 'package:sort_sphere/repositories/progress_repository.dart';
import 'package:sort_sphere/services/analytics/analytics_service.dart';
import 'package:sort_sphere/services/storage/key_value_store.dart';
import 'package:sort_sphere/state/progress_controller.dart';

void main() {
  ProgressController progress() => ProgressController(repo: LocalProgressRepository(MemoryStore()), analytics: DebugAnalyticsService());

  test('playing the solver solution via taps completes and records the level', () async {
    final p = progress();
    final level = LevelCatalog.level(12);
    final g = GameController(level: level, mode: GameMode.classic, progress: p, analytics: DebugAnalyticsService());
    final path = BallSortSolver(weight: 1).findSolution(level.tubes, level.capacity).path!;
    for (final m in path) {
      g.tap(m.from);
      g.tap(m.to);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(g.status, PlayStatus.solved);
    expect(g.result!.stars, 3);
    expect(p.value.stars[12], 3);
    expect(p.value.currentLevel, 13);
    g.dispose();
  });

  test('free undos are used before inventory', () {
    final p = progress();
    final g = GameController(level: LevelCatalog.level(5), mode: GameMode.classic, progress: p, analytics: DebugAnalyticsService());
    final inv = p.inventory(Booster.undo);
    final moves = BallSortSolver.getAvailableMoves(g.engine.snapshot(), g.engine.capacity);
    for (var i = 0; i < 4; i++) {
      final m = BallSortSolver.getAvailableMoves(g.engine.snapshot(), g.engine.capacity).first;
      g.engine.moveBall(m.from, m.to);
    }
    expect(moves, isNotEmpty);
    for (var i = 0; i < 3; i++) {
      expect(g.undo(), BoosterOutcome.used);
    }
    expect(p.inventory(Booster.undo), inv);
    expect(g.undo(), BoosterOutcome.used);
    expect(p.inventory(Booster.undo), inv - 1);
    g.dispose();
  });

  test('hint uses the solver and consumes one hint', () async {
    final p = progress();
    final g = GameController(level: LevelCatalog.level(20), mode: GameMode.classic, progress: p, analytics: DebugAnalyticsService());
    final before = p.inventory(Booster.hint);
    expect(await g.hint(), BoosterOutcome.used);
    expect(p.inventory(Booster.hint), before - 1);
    g.dispose();
  });

  test('extra tube is capped per level and un-sticks the board', () {
    final p = progress();
    final g = GameController(level: LevelCatalog.level(3), mode: GameMode.classic, progress: p, analytics: DebugAnalyticsService());
    final n = g.tubes.length;
    expect(g.addTube(free: true), BoosterOutcome.used);
    expect(g.addTube(free: true), BoosterOutcome.used);
    expect(g.addTube(free: true), BoosterOutcome.unavailable);
    expect(g.tubes.length, n + 2);
    g.dispose();
  });

  test('shuffle keeps the puzzle solvable', () async {
    final p = progress();
    final level = LevelCatalog.level(30);
    final g = GameController(level: level, mode: GameMode.classic, progress: p, analytics: DebugAnalyticsService());
    expect(await g.shuffle(), BoosterOutcome.used);
    expect(BallSortSolver(maxNodes: 300000, weight: 2).findSolution(g.engine.snapshot(), level.capacity).solved, isTrue);
    g.dispose();
  });
}
