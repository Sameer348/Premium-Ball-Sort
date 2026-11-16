/// Immutable snapshot of one tube. Balls are stored bottom → top.
class TubeState {
  TubeState(List<int> balls, this.capacity) : balls = List.unmodifiable(balls);

  final List<int> balls;
  final int capacity;

  bool get isEmpty => balls.isEmpty;
  bool get isFull => balls.length >= capacity;
  int get length => balls.length;
  int get space => capacity - balls.length;
  int? get top => balls.isEmpty ? null : balls.last;

  /// All balls share one color (vacuously true when empty).
  bool get isUniform {
    for (var i = 1; i < balls.length; i++) {
      if (balls[i] != balls[0]) return false;
    }
    return true;
  }

  /// Full and single-colored: a finished tube.
  bool get isComplete => isFull && isUniform && balls.isNotEmpty;

  /// Number of same-colored balls on top.
  int get topRun {
    if (balls.isEmpty) return 0;
    var n = 1;
    for (var i = balls.length - 2; i >= 0 && balls[i] == balls.last; i--) {
      n++;
    }
    return n;
  }

  bool accepts(int color) => !isFull && (isEmpty || top == color);

  TubeState push(int color) => TubeState([...balls, color], capacity);
  TubeState pop() => TubeState(balls.sublist(0, balls.length - 1), capacity);

  @override
  String toString() => 'Tube$balls';
}
