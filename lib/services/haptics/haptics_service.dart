import 'dart:async';

import 'package:flutter/services.dart';

/// Semantic haptics. Respects the user's toggle; never throws.
class HapticsService {
  bool enabled = true;

  void _run(Future<void> Function() f) {
    if (!enabled) return;
    unawaited(f().catchError((Object _) {}));
  }

  void select() => _run(HapticFeedback.selectionClick);
  void move() => _run(HapticFeedback.lightImpact);
  void invalid() => _run(HapticFeedback.selectionClick);
  void tubeComplete() => _run(HapticFeedback.mediumImpact);
  void button() => _run(HapticFeedback.selectionClick);

  /// Three-pulse success pattern.
  void success() {
    if (!enabled) return;
    _run(HapticFeedback.mediumImpact);
    Future.delayed(const Duration(milliseconds: 110), () => _run(HapticFeedback.lightImpact));
    Future.delayed(const Duration(milliseconds: 240), () => _run(HapticFeedback.heavyImpact));
  }
}
