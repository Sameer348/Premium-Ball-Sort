import 'move.dart';
import 'tube_state.dart';

enum GameStatus { playing, stuck, solved }

/// Read-only view of the engine state, convenient for UI and tests.
class GameState {
  const GameState({
    required this.tubes,
    required this.selected,
    required this.history,
    required this.moves,
    required this.status,
    required this.undosUsed,
    required this.extraTubesAdded,
  });

  final List<TubeState> tubes;
  final int? selected;
  final List<MoveRecord> history;
  final int moves;
  final GameStatus status;
  final int undosUsed;
  final int extraTubesAdded;

  int get completedTubes => tubes.where((t) => t.isComplete).length;
}
