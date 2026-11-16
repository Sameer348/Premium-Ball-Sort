import 'dart:math' as math;
import 'dart:ui';

/// Responsive geometry for the board. Pure math: given the available area,
/// tube count and capacity, finds the row arrangement that yields the
/// largest balls, then centres everything.
class BoardLayout {
  BoardLayout._({
    required this.tubeRects,
    required this.ball,
    required this.capacity,
    required this.size,
    required this.rows,
  });

  /// Tube body rects (logical pixels).
  final List<Rect> tubeRects;

  /// Ball diameter.
  final double ball;
  final int capacity;
  final Size size;
  final int rows;

  static const double _tubeW = 1.22; // × ball
  static const double _gapW = 0.5;
  static const double _step = 1.02; // vertical ball pitch
  static const double _topPad = 0.42;
  static const double _bottomPad = 0.11;
  static const double _lift = 1.05; // head room for a lifted ball
  static const double _rowGap = 0.45;

  double get radius => ball / 2;
  double get tubeWidth => ball * _tubeW;
  double get tubeHeight => ball * (capacity * _step + _topPad + _bottomPad);

  static BoardLayout compute(Size size, int tubes, int capacity, {double maxBall = 64}) {
    var bestBall = 0.0;
    var bestRows = 1;
    final maxRows = math.min(4, tubes);
    for (var rows = 1; rows <= maxRows; rows++) {
      final perRow = (tubes / rows).ceil();
      final byW = size.width / (perRow * (_tubeW + _gapW));
      final byH = size.height / (rows * (capacity * _step + _topPad + _bottomPad + _lift) + (rows - 1) * _rowGap);
      final b = math.min(byW, byH);
      if (b > bestBall + 0.5) {
        bestBall = b;
        bestRows = rows;
      }
    }
    final ball = math.min(bestBall, maxBall).floorToDouble();
    final tw = ball * _tubeW;
    final th = ball * (capacity * _step + _topPad + _bottomPad);
    final rowH = th + ball * _lift;
    final totalH = bestRows * rowH + (bestRows - 1) * ball * _rowGap;
    final y0 = (size.height - totalH) / 2;

    // Balanced rows: earlier rows take the remainder.
    final base = tubes ~/ bestRows;
    final extra = tubes % bestRows;
    final rects = <Rect>[];
    for (var row = 0; row < bestRows; row++) {
      final count = base + (row < extra ? 1 : 0);
      final gap = math.min(ball * _gapW * 1.6, (size.width - count * tw) / (count + 1));
      final rowW = count * tw + (count - 1) * gap;
      final x0 = (size.width - rowW) / 2;
      final top = y0 + row * (rowH + ball * _rowGap) + ball * _lift;
      for (var i = 0; i < count; i++) {
        rects.add(Rect.fromLTWH(x0 + i * (tw + gap), top, tw, th));
      }
    }
    return BoardLayout._(tubeRects: rects, ball: ball, capacity: capacity, size: size, rows: bestRows);
  }

  /// Centre of the ball in [slot] (0 = bottom) of tube [tube].
  Offset slot(int tube, int slot) {
    final r = tubeRects[tube];
    return Offset(r.center.dx, r.bottom - ball * _bottomPad - radius - slot * ball * _step);
  }

  /// Where a selected ball hovers, above the tube mouth.
  Offset lifted(int tube) {
    final r = tubeRects[tube];
    return Offset(r.center.dx, r.top - ball * 0.58);
  }

  /// Generous touch target: tube plus lift area plus half the gaps.
  Rect hitRect(int tube) {
    final r = tubeRects[tube];
    return Rect.fromLTRB(r.left - ball * 0.3, r.top - ball * _lift, r.right + ball * 0.3, r.bottom + ball * 0.25);
  }

  int? hitTest(Offset p) {
    int? best;
    var bestD = double.infinity;
    for (var i = 0; i < tubeRects.length; i++) {
      if (hitRect(i).contains(p)) {
        final d = (tubeRects[i].center - p).distanceSquared;
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
    }
    return best;
  }
}
