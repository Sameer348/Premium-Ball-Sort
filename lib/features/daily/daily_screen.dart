import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/economy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/difficulty.dart';
import '../../models/game_mode.dart';
import '../../state/progress_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/coin_pill.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/screen_scaffold.dart';
import '../gameplay/game_launcher.dart';
import 'daily_reward_sheet.dart';

/// Daily challenge hub: today's deterministic puzzle, streak, rewards.
class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _byWeekday = [Difficulty.medium, Difficulty.medium, Difficulty.hard, Difficulty.hard, Difficulty.expert, Difficulty.master, Difficulty.master];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final rec = p.todaysDaily;
    final now = DateTime.now();
    final diff = _byWeekday[now.weekday - 1];
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    return ScreenScaffold(
      title: 'Daily Challenge',
      banner: true,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        GlassPanel(
          padding: const EdgeInsets.all(22),
          glow: AppColors.gold,
          borderColor: AppColors.gold.withValues(alpha: 0.35),
          child: Column(children: [
            Text('${_months[now.month - 1].toUpperCase()} ${now.day}', style: AppText.label.copyWith(color: AppColors.gold, letterSpacing: 3)),
            const SizedBox(height: 6),
            Text("Today's Puzzle", style: AppText.h1),
            const SizedBox(height: 4),
            Text('Same puzzle for every player today.', style: AppText.small),
            const SizedBox(height: 18),
            Row(children: [
              _Info(label: 'DIFFICULTY', value: diff.label, color: AppColors.cyan),
              _Info(label: 'BEST SCORE', value: rec.bestScore > 0 ? '${rec.bestScore}' : '—', color: AppColors.textPrimary),
              _Info(label: 'STREAK', value: '${p.value.dailyStreak}🔥', color: AppColors.amber),
            ]),
            const SizedBox(height: 18),
            if (!rec.completed)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Reward ', style: AppText.body),
                const CoinGlyph(size: 20),
                Text(' +${Economy.dailyChallengeCoins}', style: AppText.h3.copyWith(color: AppColors.gold)),
              ])
            else
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Completed in ${rec.bestMoves} moves', style: AppText.h3.copyWith(color: AppColors.success)),
              ]),
            const SizedBox(height: 18),
            GradientButton(
              label: rec.completed ? 'PLAY AGAIN' : 'PLAY',
              icon: Icons.play_arrow_rounded,
              gradient: rec.completed ? AppColors.primaryGradient : AppColors.goldGradient,
              pulse: !rec.completed,
              onTap: () => GameLauncher.play(context, mode: GameMode.daily),
            ),
            const SizedBox(height: 10),
            Text('New puzzle in ${left.inHours}h ${left.inMinutes % 60}m', style: AppText.small),
          ]),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          child: Row(children: [
            const Icon(Icons.card_giftcard_rounded, color: AppColors.gold, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('7-Day Rewards', style: AppText.h3),
                Text(p.claimableRewardIndex != null ? 'Today’s gift is waiting!' : 'Claimed today — see you tomorrow.', style: AppText.small),
              ]),
            ),
            SizedBox(width: 92, child: GlassButton(label: 'OPEN', height: 44, accent: AppColors.gold, onTap: () => showDailyRewardSheet(context))),
          ]),
        ),
      ]),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: AppText.h3.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppText.label.copyWith(fontSize: 9)),
        ]),
      );
}
