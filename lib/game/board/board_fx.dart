import '../engine/move.dart';

/// Visual/audio side-effects the game controller requests. Implemented by
/// the board animator; a no-op implementation keeps the controller
/// testable without Flutter rendering.
abstract class BoardFx {
  void select(int tube);
  void deselect(int tube);

  /// A ball of [color] travels [from] → [to]. [completes] = destination
  /// becomes a finished tube on landing.
  void move(int from, int to, int color, {required bool completes, bool undo = false});
  void invalid(int tube);
  void hint(Move? move);
  void tubeAdded();
  void reset();
  void celebrate();

  /// Completes when every ball in flight has landed.
  Future<void> settled();
}

class NoopBoardFx implements BoardFx {
  @override
  void select(int tube) {}
  @override
  void deselect(int tube) {}
  @override
  void move(int from, int to, int color, {required bool completes, bool undo = false}) {}
  @override
  void invalid(int tube) {}
  @override
  void hint(Move? move) {}
  @override
  void tubeAdded() {}
  @override
  void reset() {}
  @override
  void celebrate() {}
  @override
  Future<void> settled() async {}
}
