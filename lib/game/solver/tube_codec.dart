import 'dart:typed_data';

/// Encodes a tube (bottom → top, colors 0..9) as a base-11 integer and
/// precomputes per-code lookup tables so the solver never allocates lists
/// while expanding states.
class TubeCodec {
  TubeCodec._(this.capacity)
      : size = _pow(11, capacity),
        length = Int8List(_pow(11, capacity)),
        top = Int8List(_pow(11, capacity)),
        topRun = Int8List(_pow(11, capacity)),
        bottom = Int8List(_pow(11, capacity)),
        bottomRun = Int8List(_pow(11, capacity)),
        valid = Uint8List(_pow(11, capacity)) {
    _build(0, 0);
  }

  static final Map<int, TubeCodec> _cache = {};

  /// Shared codec per capacity (tables are immutable after construction).
  factory TubeCodec.of(int capacity) {
    if (capacity < 1 || capacity > 6) {
      throw ArgumentError.value(capacity, 'capacity', 'must be 1..6');
    }
    return _cache.putIfAbsent(capacity, () => TubeCodec._(capacity));
  }

  static const int maxColors = 10;

  final int capacity;
  final int size;
  final Int8List length;
  final Int8List top; // -1 when empty
  final Int8List topRun;
  final Int8List bottom; // -1 when empty
  final Int8List bottomRun;
  final Uint8List valid;

  static int _pow(int b, int e) {
    var r = 1;
    for (var i = 0; i < e; i++) {
      r *= b;
    }
    return r;
  }

  void _build(int code, int len) {
    valid[code] = 1;
    final balls = decode(code);
    length[code] = len;
    if (len == 0) {
      top[code] = -1;
      bottom[code] = -1;
    } else {
      top[code] = balls.last;
      bottom[code] = balls.first;
      var r = 1;
      for (var i = len - 2; i >= 0 && balls[i] == balls.last; i--) {
        r++;
      }
      topRun[code] = r;
      var b = 1;
      for (var i = 1; i < len && balls[i] == balls.first; i++) {
        b++;
      }
      bottomRun[code] = b;
    }
    if (len == capacity) return;
    for (var c = 0; c < maxColors; c++) {
      _build(code * 11 + c + 1, len + 1);
    }
  }

  int encode(List<int> balls) {
    var code = 0;
    for (final b in balls) {
      code = code * 11 + b + 1;
    }
    return code;
  }

  List<int> decode(int code) {
    final out = <int>[];
    while (code > 0) {
      out.add(code % 11 - 1);
      code ~/= 11;
    }
    return out.reversed.toList();
  }

  int push(int code, int color) => code * 11 + color + 1;
  int pop(int code) => code ~/ 11;

  bool isComplete(int code) => length[code] == capacity && bottomRun[code] == capacity;
  bool isUniform(int code) => bottomRun[code] == length[code];
}
