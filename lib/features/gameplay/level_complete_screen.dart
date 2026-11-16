import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../game/effects/confetti.dart';
import '../../game/engine/scoring.dart';
import '../../models/game_mode.dart';
import '../../services/ads/admob_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/haptics/haptics_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/coin_pill.dart';
import '../../widgets/dialogs.dart';

enum ResultAction { next, replay, home }

/// Celebration overlay: confetti → stars one by one → score count-up →
/// coins fly in. Shown over the (brightened) board.
class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({super.key, required this.result, required this.coins, required this.mode, required this.title, this.best});

  final LevelResult result;
  final int coins;
  final GameMode mode;
  final String title;
  final int? best;

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen> with TickerProviderStateMixin {
  late final AnimationController _stars = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _count = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  final List<Timer> _timers = [];
  bool _doubled = false;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _coins = widget.coins;
    final audio = context.read<AudioService>();
    final haptics = context.read<HapticsService>();
    audio.play(Sfx.levelComplete, volume: 0.8);
    haptics.success();
    _stars.forward();
    for (var i = 0; i < widget.result.stars; i++) {
      _timers.add(Timer(Duration(milliseconds: 380 + i * 330), () {
        audio.play(Sfx.star, volume: 0.6 + i * 0.1);
        haptics.move();
      }));
    }
    _timers.add(Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      _count.forward();
      audio.play(Sfx.coin, volume: 0.6);
    }));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _stars.dispose();
    _count.dispose();
    super.dispose();
  }

  Future<void> _double() async {
    final ads = context.read<AdMobService>();
    final progress = context.read<ProgressController>();
    final earned = await ads.showRewarded(placement: 'double_coins');
    if (!mounted) return;
    if (earned) {
      progress.addCoins(widget.coins);
      context.read<AudioService>().play(Sfx.coin);
      setState(() {
        _doubled = true;
        _coins = widget.coins * 2;
      });
    } else {
      showToast(context, 'No ad available right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final reduce = context.select<SettingsController, bool>((s) => s.value.reduceMotion);
    final heading = r.perfect && widget.mode == GameMode.perfect
        ? 'PERFECT SORT'
        : widget.mode == GameMode.daily
            ? 'DAILY COMPLETE'
            : 'LEVEL COMPLETE';
    return Scaffold(
      backgroundColor: const Color(0x99040814),
      body: Stack(children: [
        if (!reduce) const Positioned.fill(child: ConfettiLayer()),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    color: AppColors.elevated.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(color: AppColors.success.withValues(alpha: 0.18), blurRadius: 60),
                      const BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 20)),
                    ],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(heading, style: AppText.label.copyWith(color: AppColors.success, fontSize: 13, letterSpacing: 3)),
                    const SizedBox(height: 4),
                    Text(widget.title, style: AppText.h1),
                    const SizedBox(height: 18),
                    _StarRow(controller: _stars, stars: r.stars),
                    const SizedBox(height: 18),
                    AnimatedBuilder(
                      animation: _count,
                      builder: (_, _) {
                        final v = Curves.easeOutCubic.transform(_count.value);
                        return Text('${(r.score * v).round()}', style: AppText.display.copyWith(fontSize: 46, letterSpacing: 1, fontFeatures: const [FontFeature.tabularFigures()]));
                      },
                    ),
                    Text('SCORE', style: AppText.label),
                    const SizedBox(height: 16),
                    Row(children: [
                      _Metric(label: 'MOVES', value: '${r.moves}'),
                      _Metric(label: 'TARGET', value: '${r.par}'),
                      _Metric(label: widget.best != null ? 'BEST' : 'TIME', value: widget.best != null ? '${widget.best}' : '${r.seconds}s'),
                    ]),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _count,
                      builder: (_, child) => Opacity(
                        opacity: _count.value,
                        child: Transform.translate(offset: Offset(0, 12 * (1 - _count.value)), child: child),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const CoinGlyph(size: 28),
                        const SizedBox(width: 8),
                        Text('+$_coins', style: AppText.h2.copyWith(color: AppColors.gold)),
                        if (!_doubled && widget.coins > 0) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _double,
                            icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.violet, size: 20),
                            label: Text('×2', style: AppText.h3.copyWith(color: AppColors.purple)),
                          ),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 18),
                    GradientButton(
                      label: widget.mode == GameMode.daily ? 'DONE' : 'NEXT LEVEL',
                      icon: widget.mode == GameMode.daily ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      pulse: true,
                      onTap: () => Navigator.pop(context, widget.mode == GameMode.daily ? ResultAction.home : ResultAction.next),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: GlassButton(label: 'REPLAY', icon: Icons.refresh_rounded, height: 52, onTap: () => Navigator.pop(context, ResultAction.replay))),
                      const SizedBox(width: 10),
                      Expanded(child: GlassButton(label: 'HOME', icon: Icons.home_rounded, accent: AppColors.textSecondary, height: 52, onTap: () => Navigator.pop(context, ResultAction.home))),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.controller, required this.stars});
  final AnimationController controller;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of 3 stars',
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) => Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < 3; i++) _star(i),
        ]),
      ),
    );
  }

  Widget _star(int i) {
    final start = 0.2 + i * 0.22;
    final t = ((controller.value - start) / 0.3).clamp(0.0, 1.0);
    final earned = i < stars;
    final s = earned ? Curves.elasticOut.transform(t) : 1.0;
    final size = i == 1 ? 72.0 : 56.0;
    return Padding(
      padding: EdgeInsets.only(bottom: i == 1 ? 10 : 0, left: 4, right: 4),
      child: Transform.rotate(
        angle: earned ? (1 - t) * -math.pi / 3 : 0,
        child: Transform.scale(
          scale: earned ? s : 1,
          child: Stack(alignment: Alignment.center, children: [
            Icon(Icons.star_rounded, size: size, color: AppColors.glassStrong),
            if (earned && t > 0)
              ShaderMask(
                shaderCallback: (r) => AppColors.goldGradient.createShader(r),
                child: Icon(Icons.star_rounded, size: size, color: Colors.white, shadows: [Shadow(color: AppColors.gold.withValues(alpha: 0.7), blurRadius: 18)]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(value, style: AppText.h3),
            const SizedBox(height: 2),
            Text(label, style: AppText.label.copyWith(fontSize: 10)),
          ]),
        ),
      );
}
