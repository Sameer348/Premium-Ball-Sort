import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/screenshot_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/game_mode.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/coin_pill.dart';
import '../game_controller.dart';

/// Minimal HUD: title + difficulty, progress toward completion, moves,
/// mode-specific timer/limit, coins, pause.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.title, required this.onPause, required this.onHome});

  final String title;
  final VoidCallback onPause;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final total = g.colorCount;
    final done = g.completedTubes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(children: [
        Row(children: [
          IconCircleButton(icon: Icons.home_rounded, label: 'Home', onTap: onHome),
          Expanded(
            child: Column(children: [
              GestureDetector(
                // Screenshot mode only: long-press the title to auto-solve.
                onLongPress: screenshotMode ? g.debugAutoSolve : null,
                child: Text(title, style: AppText.h2.copyWith(letterSpacing: 1.5)),
              ),
              const SizedBox(height: 2),
              _DifficultyChip(label: g.level.difficulty.label),
            ]),
          ),
          IconCircleButton(icon: Icons.pause_rounded, label: 'Pause', onTap: onPause),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _Stat(
            icon: Icons.swap_vert_rounded,
            label: g.mode == GameMode.perfect ? '${g.movesLeft} left' : '${g.moves}',
            color: g.mode == GameMode.perfect && g.movesLeft <= 3 ? AppColors.coral : AppColors.textPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(child: _Progress(done: done, total: total)),
          const SizedBox(width: 10),
          if (g.mode == GameMode.timeAttack)
            _Stat(icon: Icons.timer_rounded, label: _fmt(g.timeLeft), color: g.timeLeft <= 10 ? AppColors.coral : AppColors.cyan)
          else
            const CoinPill(),
        ]),
      ]),
    );
  }

  static String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.glass),
        child: Text(label.toUpperCase(), style: AppText.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, this.color = AppColors.textPrimary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(label, style: AppText.number.copyWith(color: color)),
        ]),
      );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final v = total == 0 ? 0.0 : done / total;
    return Semantics(
      label: '$done of $total tubes sorted',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('$done / $total SORTED', style: AppText.label.copyWith(fontSize: 10)),
        const SizedBox(height: 5),
        Container(
          height: 8,
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(4)),
          child: LayoutBuilder(
            builder: (_, c) => Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: c.maxWidth * v,
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
