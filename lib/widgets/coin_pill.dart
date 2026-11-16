import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../state/progress_controller.dart';

/// Coin counter that bounces and counts up/down when the balance changes.
class CoinPill extends StatefulWidget {
  const CoinPill({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  State<CoinPill> createState() => _CoinPillState();
}

class _CoinPillState extends State<CoinPill> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  int? _last;

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = context.select<ProgressController, int>((p) => p.coins);
    if (_last != null && _last != coins) _bounce.forward(from: 0);
    final from = _last ?? coins;
    _last = coins;
    return Semantics(
      label: '$coins coins',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _bounce,
          builder: (_, child) {
            final t = _bounce.value;
            final s = 1 + (t < 0.3 ? t / 0.3 : (1 - (t - 0.3) / 0.7)) * 0.12;
            return Transform.scale(scale: _bounce.isAnimating ? s : 1, child: child);
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.only(left: 6, right: 14),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const CoinGlyph(size: 28),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: from.toDouble(), end: coins.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text('${v.round()}', style: AppText.number.copyWith(color: AppColors.gold)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class CoinGlyph extends StatelessWidget {
  const CoinGlyph({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFF1C1), AppColors.gold, Color(0xFFD9932B)], stops: [0, 0.5, 1]),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 8)],
        ),
        child: Icon(Icons.auto_awesome, size: size * 0.5, color: const Color(0xFF8A5A12)),
      );
}
