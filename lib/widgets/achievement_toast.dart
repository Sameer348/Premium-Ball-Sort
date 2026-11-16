import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../features/achievements/achievement_icons.dart';
import '../models/achievement.dart';
import '../services/audio/audio_service.dart';
import '../services/haptics/haptics_service.dart';
import '../state/progress_controller.dart';
import 'coin_pill.dart';

/// App-wide host that slides in a glowing banner for each newly unlocked
/// achievement (queued, one at a time).
class AchievementToastHost extends StatefulWidget {
  const AchievementToastHost({super.key, required this.child});
  final Widget child;

  @override
  State<AchievementToastHost> createState() => _AchievementToastHostState();
}

class _AchievementToastHostState extends State<AchievementToastHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  final Queue<Achievement> _queue = Queue();
  StreamSubscription<Achievement>? _sub;
  Achievement? _current;

  @override
  void initState() {
    super.initState();
    _sub = context.read<ProgressController>().unlocks.listen((a) {
      _queue.add(a);
      if (_current == null) _next();
    });
  }

  Future<void> _next() async {
    if (_queue.isEmpty || !mounted) {
      setState(() => _current = null);
      return;
    }
    setState(() => _current = _queue.removeFirst());
    // Let level-complete animations breathe first.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.read<AudioService>().play(Sfx.achievement, volume: 0.7);
    context.read<HapticsService>().success();
    await _c.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    await _c.reverse();
    _next();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _current;
    return Stack(children: [
      widget.child,
      if (a != null)
        Positioned(
          left: 16,
          right: 16,
          top: MediaQuery.paddingOf(context).top + 8,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) {
                final t = Curves.easeOutBack.transform(_c.value.clamp(0, 1));
                return Opacity(
                  opacity: _c.value.clamp(0.0, 1.0),
                  child: Transform.translate(offset: Offset(0, -40 * (1 - t)), child: Transform.scale(scale: 0.9 + 0.1 * t, child: child)),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.violet.withValues(alpha: 0.6)),
                    boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.35), blurRadius: 30)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.premiumGradient),
                      child: Icon(achievementIcon(a), color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('ACHIEVEMENT UNLOCKED', style: AppText.label.copyWith(color: AppColors.purple, fontSize: 11)),
                        Text(a.title, style: AppText.h3),
                      ]),
                    ),
                    const CoinGlyph(size: 20),
                    const SizedBox(width: 4),
                    Text('+${a.reward}', style: AppText.number.copyWith(color: AppColors.gold)),
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
