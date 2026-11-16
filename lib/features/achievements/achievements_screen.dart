import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/achievement.dart';
import '../../state/progress_controller.dart';
import '../../widgets/coin_pill.dart';
import '../../widgets/screen_scaffold.dart';
import 'achievement_icons.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final unlocked = p.value.achievements;
    final list = [...Achievement.all]..sort((a, b) {
        final ua = unlocked.contains(a.id) ? 1 : 0;
        final ub = unlocked.contains(b.id) ? 1 : 0;
        return ua - ub;
      });
    return ScreenScaffold(
      title: 'Achievements',
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        _Summary(done: unlocked.length, total: Achievement.all.length, levels: p.value.completedLevels, stars: p.value.totalStars),
        const SizedBox(height: 14),
        for (final a in list) _AchievementTile(a: a, unlocked: unlocked.contains(a.id), progress: p.achievementProgress(a)),
      ]),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.done, required this.total, required this.levels, required this.stars});
  final int done, total, levels, stars;

  @override
  Widget build(BuildContext context) {
    Widget stat(String v, String l, Color c) => Expanded(
          child: Column(children: [
            Text(v, style: AppText.h2.copyWith(color: c)),
            Text(l, style: AppText.label.copyWith(fontSize: 10)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: [AppColors.violet.withValues(alpha: 0.2), AppColors.surface]),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        stat('$done/$total', 'UNLOCKED', AppColors.purple),
        stat('$levels', 'LEVELS', AppColors.textPrimary),
        stat('$stars', 'STARS', AppColors.gold),
      ]),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.a, required this.unlocked, required this.progress});
  final Achievement a;
  final bool unlocked;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final v = (progress / a.goal).clamp(0.0, 1.0);
    return Semantics(
      label: '${a.title}. ${a.description}. ${unlocked ? 'Unlocked' : '$progress of ${a.goal}'}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: unlocked ? AppColors.violet.withValues(alpha: 0.55) : AppColors.glassBorder),
          boxShadow: [if (unlocked) BoxShadow(color: AppColors.violet.withValues(alpha: 0.15), blurRadius: 16)],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked ? AppColors.premiumGradient : null,
              color: unlocked ? null : AppColors.glass,
            ),
            child: Icon(unlocked ? achievementIcon(a) : Icons.lock_outline_rounded, color: unlocked ? Colors.white : AppColors.textDisabled),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: AppText.h3.copyWith(fontSize: 15, color: unlocked ? AppColors.textPrimary : AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(a.description, style: AppText.small),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: AppColors.glass,
                  valueColor: AlwaysStoppedAnimation(unlocked ? AppColors.purple : AppColors.cyan),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Column(children: [
            const CoinGlyph(size: 20),
            const SizedBox(height: 2),
            Text('${a.reward}', style: AppText.small.copyWith(color: AppColors.gold, fontWeight: FontWeight.w800)),
            Text(unlocked ? '✓' : '${progress.clamp(0, a.goal)}/${a.goal}', style: AppText.small.copyWith(fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}
