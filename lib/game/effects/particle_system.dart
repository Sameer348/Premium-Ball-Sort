import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Fixed-capacity, allocation-free particle pool (struct-of-arrays).
class ParticleSystem {
  ParticleSystem({this.capacity = 220});

  final int capacity;
  late final Float32List _x = Float32List(capacity);
  late final Float32List _y = Float32List(capacity);
  late final Float32List _vx = Float32List(capacity);
  late final Float32List _vy = Float32List(capacity);
  late final Float32List _life = Float32List(capacity);
  late final Float32List _maxLife = Float32List(capacity);
  late final Float32List _size = Float32List(capacity);
  late final Float32List _gravity = Float32List(capacity);
  late final Int32List _color = Int32List(capacity);
  late final Uint8List _sparkle = Uint8List(capacity);
  int _cursor = 0;
  int _alive = 0;
  final math.Random _rng = math.Random(7);
  final Paint _paint = Paint();
  final Path _star = Path();

  /// Multiplier from graphics quality (0.4 low, 1 high).
  double density = 1;

  bool get isActive => _alive > 0;

  void burst(Offset at, Color color, {int count = 8, double speed = 120, double size = 2.4, double life = 0.55, double gravity = 260, bool sparkle = false, double spreadUp = 0}) {
    final n = math.max(1, (count * density).round());
    for (var k = 0; k < n; k++) {
      final i = _cursor;
      _cursor = (_cursor + 1) % capacity;
      if (_life[i] <= 0) _alive++;
      final a = _rng.nextDouble() * math.pi * 2;
      final s = speed * (0.35 + _rng.nextDouble() * 0.65);
      _x[i] = at.dx;
      _y[i] = at.dy;
      _vx[i] = math.cos(a) * s;
      _vy[i] = math.sin(a) * s - spreadUp;
      _maxLife[i] = life * (0.7 + _rng.nextDouble() * 0.6);
      _life[i] = _maxLife[i];
      _size[i] = size * (0.6 + _rng.nextDouble() * 0.8);
      _gravity[i] = gravity;
      _color[i] = color.toARGB32();
      _sparkle[i] = sparkle ? 1 : 0;
    }
  }

  void update(double dt) {
    if (_alive == 0) return;
    var alive = 0;
    for (var i = 0; i < capacity; i++) {
      if (_life[i] <= 0) continue;
      _life[i] -= dt;
      if (_life[i] <= 0) continue;
      alive++;
      _vy[i] += _gravity[i] * dt;
      _vx[i] *= 0.985;
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
    }
    _alive = alive;
  }

  void paint(Canvas canvas) {
    if (_alive == 0) return;
    for (var i = 0; i < capacity; i++) {
      final l = _life[i];
      if (l <= 0) continue;
      final t = l / _maxLife[i];
      final c = Color(_color[i]);
      _paint.color = c.withValues(alpha: (t * 1.4).clamp(0.0, 1.0));
      final s = _size[i] * (0.4 + t * 0.6);
      if (_sparkle[i] == 1) {
        _star
          ..reset()
          ..moveTo(_x[i], _y[i] - s * 2)
          ..lineTo(_x[i] + s * 0.45, _y[i] - s * 0.45)
          ..lineTo(_x[i] + s * 2, _y[i])
          ..lineTo(_x[i] + s * 0.45, _y[i] + s * 0.45)
          ..lineTo(_x[i], _y[i] + s * 2)
          ..lineTo(_x[i] - s * 0.45, _y[i] + s * 0.45)
          ..lineTo(_x[i] - s * 2, _y[i])
          ..lineTo(_x[i] - s * 0.45, _y[i] - s * 0.45)
          ..close();
        canvas.drawPath(_star, _paint);
      } else {
        canvas.drawCircle(Offset(_x[i], _y[i]), s, _paint);
      }
    }
  }

  void clear() {
    for (var i = 0; i < capacity; i++) {
      _life[i] = 0;
    }
    _alive = 0;
  }
}
