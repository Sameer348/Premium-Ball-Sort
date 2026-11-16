import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/daily_reward.dart';
import '../../services/audio/audio_service.dart';
import '../../services/haptics/haptics_service.dart';
import '../../state/progress_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';

IconData rewardIcon(RewardKind k) => switch (k) {
      RewardKind.coins => Icons.toll_rounded,
      RewardKind.hint => Icons.lightbulb_rounded,
      RewardKind.undo => Icons.undo_rounded,
      RewardKind.extraTube => Icons.add_box_rounded,
      RewardKind.skin => Icons.blur_circular_rounded,
      RewardKind.premium => Icons.diamond_rounded,
    };

/// 7-day reward calendar. Missing a day restarts the cycle (gently).
Future<void> showDailyRewardSheet(BuildContext context) {
  return showGlassDialog<void>(context, builder: (ctx) => const _DailyRewardContent());
}

class _DailyRewardContent extends StatefulWidget {
  const _DailyRewardContent();

  @override
  State<_DailyRewardContent> createState() => _DailyRewardContentState();
}

class _DailyRewardContentState extends State<_DailyRewardContent> {
  DailyReward? _claimed;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final claimable = p.claimableRewardIndex;
    final cursor = p.rewardCursor;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DialogHeader(
        icon: Icons.card_giftcard_rounded,
        title: _claimed != null ? 'Enjoy!' : 'Daily Reward',
        subtitle: _claimed != null ? 'You received ${_claimed!.label}.' : 'Come back every day for bigger gifts.',
        color: AppColors.gold,
      ),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < 7; i++) _DayTile(reward: DailyReward.cycle[i], state: _stateFor(i, claimable, cursor, p.value.dailyRewardDay)),
      ]),
      const SizedBox(height: 20),
      if (claimable != null && _claimed == null)
        GradientButton(
          label: 'CLAIM',
          icon: Icons.redeem_rounded,
          gradient: AppColors.goldGradient,
          pulse: true,
          onTap: () {
            final r = p.claimDailyReward();
            if (r == null) return;
            context.read<AudioService>().play(Sfx.coin);
            context.read<HapticsService>().success();
            setState(() => _claimed = r);
          },
        )
      else
        GlassButton(label: 'CLOSE', onTap: () => Navigator.pop(context)),
    ]);
  }

  _DayState _stateFor(int i, int? claimable, int cursor, int claimedDays) {
    if (claimable != null) {
      if (i < claimable) return _DayState.claimed;
      if (i == claimable) return _claimed != null ? _DayState.claimed : _DayState.today;
      return _DayState.locked;
    }
    if (i < claimedDays) return _DayState.claimed;
    return _DayState.locked;
  }
}

enum _DayState { claimed, today, locked }

class _DayTile extends StatelessWidget {
  const _DayTile({required this.reward, required this.state});
  final DailyReward reward;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final today = state == _DayState.today;
    final premium = reward.kind == RewardKind.premium;
    final color = premium ? AppColors.violet : AppColors.gold;
    return Semantics(
      label: 'Day ${reward.day}: ${reward.label}, ${state.name}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: premium ? 152 : 72,
        height: 92,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: today ? color.withValues(alpha: 0.16) : AppColors.glass,
          border: Border.all(color: today ? color : (state == _DayState.claimed ? AppColors.success.withValues(alpha: 0.5) : AppColors.glassBorder), width: today ? 2 : 1),
          boxShadow: [if (today) BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18)],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('DAY ${reward.day}', style: AppText.label.copyWith(fontSize: 9, color: today ? color : AppColors.textMuted)),
          state == _DayState.claimed
              ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28)
              : Icon(rewardIcon(reward.kind), color: state == _DayState.locked ? color.withValues(alpha: 0.5) : color, size: 28),
          Text(reward.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
