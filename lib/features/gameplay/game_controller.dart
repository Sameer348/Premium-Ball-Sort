import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/economy.dart';
import '../../game/board/board_fx.dart';
import '../../game/engine/ball_sort_engine.dart';
import '../../game/engine/scoring.dart';
import '../../game/engine/tube_state.dart';
import '../../game/solver/ball_sort_solver.dart';
import '../../game/solver/solver_isolate.dart';
import '../../models/booster.dart';
import '../../models/game_mode.dart';
import '../../models/level_data.dart';
import '../../services/analytics/analytics_service.dart';
import '../../state/progress_controller.dart';

enum PlayStatus { playing, paused, stuck, solved, timeUp, outOfMoves }

/// What happened when the player asked for a booster.
enum BoosterOutcome { used, needsMore, unavailable, busy }

/// Gameplay state for one puzzle. Bridges the pure engine to visual
/// effects ([BoardFx]) and persistent progress. UI-agnostic beyond
/// ChangeNotifier.
class GameController extends ChangeNotifier {
  GameController({
    required this.level,
    required this.mode,
    required this.progress,
    required this.analytics,
    this.endlessIndex = 0,
  }) : engine = BallSortEngine(level) {
    _freeUndos = Economy.freeUndosPerLevel;
    if (mode == GameMode.timeAttack) timeLeft = _timeLimitFor(level);
    if (mode == GameMode.perfect) moveLimit = level.par + (level.par * 0.15).ceil() + 2;
    analytics.log(AnalyticsEvent.levelStarted, {'level': level.number, 'mode': mode.name});
  }

  final LevelData level;
  final GameMode mode;
  final ProgressController progress;
  final AnalyticsService analytics;
  final int endlessIndex;
  final BallSortEngine engine;
  BoardFx fx = NoopBoardFx();

  PlayStatus status = PlayStatus.playing;
  PlayStatus? _beforePause;
  int seconds = 0;
  int timeLeft = 0;
  int moveLimit = 0;
  int _freeUndos = 0;
  int hintsUsed = 0;
  bool _busy = false;
  bool continued = false;
  LevelResult? result;
  int coinsEarned = 0;
  Timer? _timer;

  List<TubeState> get tubes => engine.tubes;
  int? get selected => engine.selected;
  int get moves => engine.moves;
  bool get canUndo => engine.canUndo && status == PlayStatus.playing;
  bool get busy => _busy;
  int get freeUndos => _freeUndos;
  int get completedTubes => engine.tubes.where((t) => t.isComplete).length;
  int get colorCount => level.colorCount;
  bool get isTutorial => mode == GameMode.classic && level.number <= 3;
  int get movesLeft => moveLimit - engine.moves;
  bool get canAddTube => engine.extraTubesAdded < Economy.maxExtraTubesPerLevel;

  static int _timeLimitFor(LevelData l) => 30 + l.colorCount * 18;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onSecond());
  }

  void _onSecond() {
    if (status != PlayStatus.playing) return;
    seconds++;
    if (mode == GameMode.timeAttack) {
      timeLeft--;
      if (timeLeft <= 0) {
        timeLeft = 0;
        status = PlayStatus.timeUp;
        engine.clearSelection();
        analytics.log(AnalyticsEvent.levelFailed, {'reason': 'time'});
      }
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- input

  void tap(int tube) {
    if (status != PlayStatus.playing) return;
    final r = engine.selectTube(tube);
    switch (r.kind) {
      case TapKind.selected:
      case TapKind.reselected:
        fx.select(tube);
      case TapKind.deselected:
        fx.deselect(tube);
      case TapKind.invalid:
        fx.invalid(tube);
        if (r.previous != null) {
          // Keep the selection — the player may just have mis-tapped.
        }
      case TapKind.moved:
        final rec = r.record!;
        fx.move(rec.move.from, rec.move.to, rec.color, completes: rec.completedTube);
        analytics.log(AnalyticsEvent.ballMoved);
        _afterMove();
      case TapKind.ignored:
        break;
    }
    notifyListeners();
  }

  void _afterMove() {
    if (engine.isSolved()) {
      unawaited(_onSolved());
      return;
    }
    if (mode == GameMode.perfect && engine.moves >= moveLimit) {
      status = PlayStatus.outOfMoves;
      analytics.log(AnalyticsEvent.levelFailed, {'reason': 'moves'});
      return;
    }
    if (engine.isStuck()) _becomeStuckAfterLanding();
  }

  void _becomeStuckAfterLanding() {
    status = PlayStatus.stuck;
    unawaited(fx.settled().then((_) => notifyListeners()));
  }

  Future<void> _onSolved() async {
    status = PlayStatus.solved;
    _timer?.cancel();
    notifyListeners();
    await fx.settled();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    fx.celebrate();
    final firstClear = mode != GameMode.classic || !progress.value.stars.containsKey(level.number);
    final mult = switch (mode) {
      GameMode.perfect => Economy.perfectModeMultiplier,
      GameMode.timeAttack => Economy.timeAttackMultiplier,
      _ => 1.0,
    };
    final r = Scoring.evaluate(
      moves: engine.moves,
      par: level.par,
      colors: level.colorCount,
      seconds: seconds,
      usedUndo: engine.undosUsed > 0,
      usedHint: hintsUsed > 0,
      firstClear: firstClear,
      coinMultiplier: mult,
      timeBonusSeconds: mode == GameMode.timeAttack ? timeLeft : 0,
    );
    result = r;
    coinsEarned = progress.recordResult(mode: mode, level: level.number, r: r, tubesCompleted: completedTubes, endlessIndex: endlessIndex);
    analytics.log(AnalyticsEvent.levelCompleted, {'level': level.number, 'mode': mode.name, 'moves': r.moves, 'stars': r.stars});
    notifyListeners();
  }

  // ---------------------------------------------------------- boosters

  BoosterOutcome undo() {
    if (!engine.canUndo || (status != PlayStatus.playing && status != PlayStatus.stuck && status != PlayStatus.outOfMoves)) {
      return BoosterOutcome.unavailable;
    }
    if (_freeUndos > 0) {
      _freeUndos--;
    } else if (!progress.consumeBooster(Booster.undo)) {
      return BoosterOutcome.needsMore;
    }
    final rec = engine.undo()!;
    fx.move(rec.move.to, rec.move.from, rec.color, completes: false, undo: true);
    analytics.log(AnalyticsEvent.undoUsed);
    if (status == PlayStatus.stuck || status == PlayStatus.outOfMoves) status = PlayStatus.playing;
    notifyListeners();
    return BoosterOutcome.used;
  }

  /// Screenshot mode only (see `core/screenshot_mode.dart`): plays the
  /// solver's solution from the current position, a move at a time.
  Future<void> debugAutoSolve() async {
    final path = BallSortSolver().findSolution(engine.snapshot(), engine.capacity).path;
    for (final m in path ?? const []) {
      if (status != PlayStatus.playing) return;
      tap(m.from);
      await Future<void>.delayed(const Duration(milliseconds: 160));
      tap(m.to);
      await Future<void>.delayed(const Duration(milliseconds: 380));
    }
  }

  Future<BoosterOutcome> hint() async {
    if (_busy) return BoosterOutcome.busy;
    if (status != PlayStatus.playing && status != PlayStatus.stuck) return BoosterOutcome.unavailable;
    if (progress.inventory(Booster.hint) <= 0) return BoosterOutcome.needsMore;
    _busy = true;
    notifyListeners();
    final r = await computeHint(engine.snapshot(), engine.capacity);
    _busy = false;
    switch (r.status) {
      case HintStatus.found:
        progress.consumeBooster(Booster.hint);
        hintsUsed++;
        engine.clearSelection();
        fx.hint(r.move);
        analytics.log(AnalyticsEvent.hintUsed);
        notifyListeners();
        return BoosterOutcome.used;
      case HintStatus.unsolvable:
        status = PlayStatus.stuck;
        notifyListeners();
        return BoosterOutcome.unavailable;
      case HintStatus.alreadySolved:
      case HintStatus.unknown:
        notifyListeners();
        return BoosterOutcome.unavailable;
    }
  }

  BoosterOutcome addTube({bool free = false}) {
    if (!canAddTube) return BoosterOutcome.unavailable;
    if (!free && !progress.consumeBooster(Booster.extraTube)) return BoosterOutcome.needsMore;
    engine.addTube(maxExtra: Economy.maxExtraTubesPerLevel);
    fx.tubeAdded();
    analytics.log(AnalyticsEvent.extraTubeUsed);
    if (status == PlayStatus.stuck) status = PlayStatus.playing;
    notifyListeners();
    return BoosterOutcome.used;
  }

  Future<BoosterOutcome> shuffle() async {
    if (_busy || (status != PlayStatus.playing && status != PlayStatus.stuck)) return BoosterOutcome.unavailable;
    if (progress.inventory(Booster.shuffle) <= 0) return BoosterOutcome.needsMore;
    _busy = true;
    notifyListeners();
    final next = await computeShuffle(engine.snapshot(), engine.capacity, DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF);
    _busy = false;
    if (next == null) {
      notifyListeners();
      return BoosterOutcome.unavailable;
    }
    progress.consumeBooster(Booster.shuffle);
    engine.replaceTubes(next);
    fx.reset();
    if (status == PlayStatus.stuck) status = PlayStatus.playing;
    analytics.log(AnalyticsEvent.shuffleUsed);
    notifyListeners();
    return BoosterOutcome.used;
  }

  void restart() {
    engine.restart();
    status = PlayStatus.playing;
    seconds = 0;
    hintsUsed = 0;
    _freeUndos = Economy.freeUndosPerLevel;
    if (mode == GameMode.timeAttack) timeLeft = _timeLimitFor(level);
    continued = false;
    result = null;
    fx.reset();
    start();
    notifyListeners();
  }

  /// Rewarded "continue": more time or more moves.
  void continueAfterReward() {
    continued = true;
    if (status == PlayStatus.timeUp) timeLeft += 30;
    if (status == PlayStatus.outOfMoves) moveLimit += 10;
    status = PlayStatus.playing;
    notifyListeners();
  }

  void dismissStuck() {
    if (status == PlayStatus.stuck) status = PlayStatus.playing;
    notifyListeners();
  }

  void pause() {
    if (status == PlayStatus.paused || status == PlayStatus.solved) return;
    _beforePause = status;
    status = PlayStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (status != PlayStatus.paused) return;
    status = _beforePause ?? PlayStatus.playing;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
