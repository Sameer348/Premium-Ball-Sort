import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/booster.dart';
import '../../../services/ads/admob_service.dart';
import '../../../services/audio/audio_service.dart';
import '../../../state/progress_controller.dart';
import '../../../state/settings_controller.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/coin_pill.dart';
import '../../../widgets/dialogs.dart';

IconData boosterIcon(Booster b) => switch (b) {
      Booster.hint => Icons.lightbulb_rounded,
      Booster.undo => Icons.undo_rounded,
      Booster.extraTube => Icons.add_box_rounded,
      Booster.shuffle => Icons.shuffle_rounded,
    };

Color boosterColor(Booster b) => switch (b) {
      Booster.hint => AppColors.cyan,
      Booster.undo => AppColors.blue,
      Booster.extraTube => AppColors.success,
      Booster.shuffle => AppColors.purple,
    };

/// Offers coins or a rewarded ad when a booster is out of stock.
/// Resolves true when the player now owns at least one.
Future<bool> showGetBooster(BuildContext context, Booster b) async {
  final progress = context.read<ProgressController>();
  final ads = context.read<AdMobService>();
  final audio = context.read<AudioService>();
  final price = ProgressController.priceOf(b);
  final result = await showGlassDialog<bool>(context, builder: (ctx) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DialogHeader(icon: boosterIcon(b), title: 'Need a ${b.label}?', subtitle: b.description, color: boosterColor(b)),
      GradientButton(
        label: 'BUY FOR $price',
        icon: Icons.toll_rounded,
        gradient: AppColors.goldGradient,
        height: 56,
        onTap: progress.coins >= price
            ? () {
                if (progress.buyBooster(b)) {
                  audio.play(Sfx.coin);
                  Navigator.pop(ctx, true);
                }
              }
            : null,
      ),
      const SizedBox(height: 12),
      GlassButton(
        label: 'WATCH AD — FREE',
        icon: Icons.play_circle_fill_rounded,
        accent: AppColors.violet,
        onTap: () async {
          final earned = await ads.showRewarded(placement: 'booster_${b.name}');
          if (!ctx.mounted) return;
          if (earned) {
            progress.grantBooster(b, 1);
            audio.play(Sfx.booster);
            Navigator.pop(ctx, true);
          } else {
            showToast(ctx, 'No ad available right now. Try again soon.');
          }
        },
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Not now', style: AppText.body.copyWith(color: AppColors.textMuted))),
    ]);
  });
  return result ?? false;
}

enum StuckChoice { undo, hint, addTube, restart, keepLooking }

Future<StuckChoice> showStuckDialog(BuildContext context, {required bool canAddTube}) async {
  final r = await showGlassDialog<StuckChoice>(context, builder: (ctx) {
    Widget opt(StuckChoice c, String label, IconData icon, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassButton(label: label, icon: icon, accent: color, height: 52, onTap: () => Navigator.pop(ctx, c)),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const DialogHeader(
        icon: Icons.psychology_alt_rounded,
        title: 'Looks tricky!',
        subtitle: 'No useful moves left on this path. No worries — pick a way forward.',
        color: AppColors.amber,
      ),
      opt(StuckChoice.undo, 'UNDO', Icons.undo_rounded, AppColors.blue),
      opt(StuckChoice.hint, 'HINT', Icons.lightbulb_rounded, AppColors.cyan),
      if (canAddTube) opt(StuckChoice.addTube, 'ADD TUBE', Icons.add_box_rounded, AppColors.success),
      opt(StuckChoice.restart, 'RESTART', Icons.refresh_rounded, AppColors.textSecondary),
      TextButton(onPressed: () => Navigator.pop(ctx, StuckChoice.keepLooking), child: Text('Keep looking', style: AppText.body.copyWith(color: AppColors.textMuted))),
    ]);
  });
  return r ?? StuckChoice.keepLooking;
}

enum FailChoice { continueAd, retry, home }

Future<FailChoice> showFailDialog(BuildContext context, {required bool timeUp, required bool canContinue}) async {
  final ads = context.read<AdMobService>();
  final r = await showGlassDialog<FailChoice>(context, dismissible: false, builder: (ctx) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DialogHeader(
        icon: timeUp ? Icons.timer_off_rounded : Icons.flag_rounded,
        title: timeUp ? "Time's up!" : 'Out of moves',
        subtitle: timeUp ? 'So close. Want 30 more seconds?' : 'Want 10 extra moves to finish?',
        color: AppColors.coral,
      ),
      if (canContinue)
        GradientButton(
          label: timeUp ? '+30 SECONDS' : '+10 MOVES',
          subtitle: 'Watch a short ad',
          icon: Icons.play_circle_fill_rounded,
          gradient: AppColors.premiumGradient,
          textColor: Colors.white,
          height: 60,
          onTap: () async {
            final earned = await ads.showRewarded(placement: 'continue');
            if (!ctx.mounted) return;
            if (earned) {
              Navigator.pop(ctx, FailChoice.continueAd);
            } else {
              showToast(ctx, 'No ad available right now.');
            }
          },
        ),
      const SizedBox(height: 12),
      GlassButton(label: 'TRY AGAIN', icon: Icons.refresh_rounded, onTap: () => Navigator.pop(ctx, FailChoice.retry)),
      const SizedBox(height: 10),
      GlassButton(label: 'HOME', icon: Icons.home_rounded, accent: AppColors.textSecondary, onTap: () => Navigator.pop(ctx, FailChoice.home)),
    ]);
  });
  return r ?? FailChoice.retry;
}

enum PauseChoice { resume, restart, home }

Future<PauseChoice> showPauseDialog(BuildContext context) async {
  final r = await showGlassDialog<PauseChoice>(context, builder: (ctx) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const DialogHeader(icon: Icons.pause_rounded, title: 'Paused', subtitle: 'Take your time.'),
      const _QuickToggles(),
      const SizedBox(height: 18),
      GradientButton(label: 'RESUME', icon: Icons.play_arrow_rounded, height: 58, onTap: () => Navigator.pop(ctx, PauseChoice.resume)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: GlassButton(label: 'RESTART', icon: Icons.refresh_rounded, height: 52, onTap: () => Navigator.pop(ctx, PauseChoice.restart))),
        const SizedBox(width: 10),
        Expanded(child: GlassButton(label: 'HOME', icon: Icons.home_rounded, accent: AppColors.textSecondary, height: 52, onTap: () => Navigator.pop(ctx, PauseChoice.home))),
      ]),
    ]);
  });
  return r ?? PauseChoice.resume;
}

class _QuickToggles extends StatelessWidget {
  const _QuickToggles();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final v = s.value;
    Widget t(IconData on, IconData off, bool value, String label, ValueChanged<bool> set) => IconCircleButton(
          icon: value ? on : off,
          label: '$label ${value ? 'on' : 'off'}',
          size: 54,
          color: value ? AppColors.cyan : AppColors.textDisabled,
          onTap: () => set(!value),
        );
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      t(Icons.music_note_rounded, Icons.music_off_rounded, v.music, 'Music', (x) => s.update(v.copyWith(music: x))),
      t(Icons.volume_up_rounded, Icons.volume_off_rounded, v.sfx, 'Sound', (x) => s.update(v.copyWith(sfx: x))),
      t(Icons.vibration_rounded, Icons.mobile_off_rounded, v.haptics, 'Haptics', (x) => s.update(v.copyWith(haptics: x))),
    ]);
  }
}

/// Small coin-reward line used in dialogs.
class CoinReward extends StatelessWidget {
  const CoinReward({super.key, required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const CoinGlyph(size: 22),
        const SizedBox(width: 6),
        Text('+$amount', style: AppText.h3.copyWith(color: AppColors.gold)),
      ]);
}
