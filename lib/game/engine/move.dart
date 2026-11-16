/// A single-ball move from tube [from] to tube [to].
class Move {
  const Move(this.from, this.to);
  final int from;
  final int to;

  Move get reversed => Move(to, from);

  @override
  bool operator ==(Object other) => other is Move && other.from == from && other.to == to;

  @override
  int get hashCode => from * 1000 + to;

  @override
  String toString() => '$from→$to';
}

/// History entry: enough to restore the board, selection and counters.
class MoveRecord {
  const MoveRecord({
    required this.move,
    required this.color,
    required this.movesBefore,
    required this.selectedBefore,
    required this.completedTube,
  });

  final Move move;
  final int color;
  final int movesBefore;
  final int? selectedBefore;

  /// Whether this move completed the destination tube.
  final bool completedTube;
}
