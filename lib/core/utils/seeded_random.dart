/// Platform-independent deterministic PRNG (mulberry32).
///
/// `dart:math`'s [Random] makes no cross-version guarantee about its
/// sequence, so puzzles (and the daily challenge) use this instead: the same
/// seed always yields the same puzzle on every device and SDK version.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  /// Next unsigned 32-bit value.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t ^= (t + _imul(t ^ (t >>> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >>> 14)) & 0xFFFFFFFF;
  }

  /// Uniform integer in `[0, max)`.
  int nextInt(int max) {
    assert(max > 0);
    return nextUint32() % max;
  }

  double nextDouble() => nextUint32() / 4294967296.0;

  bool nextBool() => (nextUint32() & 1) == 1;

  /// In-place Fisher–Yates shuffle.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  /// Avalanche hash used to derive well-spread seeds from small integers.
  static int hash(int x) {
    var h = x & 0xFFFFFFFF;
    h ^= h >>> 16;
    h = _imul(h, 0x7FEB352D);
    h ^= h >>> 15;
    h = _imul(h, 0x846CA68B);
    h ^= h >>> 16;
    return h & 0xFFFFFFFF;
  }
}
