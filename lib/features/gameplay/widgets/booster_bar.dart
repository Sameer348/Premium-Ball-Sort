import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/booster.dart';
import '../../../state/progress_controller.dart';
import '../../../widgets/pressable.dart';
import '../game_controller.dart';

/// Bottom booster row: Undo · Hint · Extra Tube · Shuffle · Restart.
class BoosterBar extends StatelessWidget {
  const BoosterBar({super.key, required this.onBooster, required this.onRestart});

  final void Function(Booster) onBooster;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final p = context.watch<ProgressController>();
    String count(Booster b) {
      final n = b == Booster.undo ? g.freeUndos + p.inventory(b) : p.inventory(b);
      return n > 0 ? '$n' : '+';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _BoosterButton(icon: Icons.undo_rounded, label: 'Undo', badge: count(Booster.undo), enabled: g.engine.canUndo, onTap: () => onBooster(Booster.undo)),
        _BoosterButton(icon: Icons.lightbulb_rounded, label: 'Hint', badge: count(Booster.hint), accent: AppColors.cyan, busy: g.busy, onTap: () => onBooster(Booster.hint)),
        _BoosterButton(icon: Icons.add_box_rounded, label: 'Tube', badge: count(Booster.extraTube), accent: AppColors.success, enabled: g.canAddTube, onTap: () => onBooster(Booster.extraTube)),
        _BoosterButton(icon: Icons.shuffle_rounded, label: 'Shuffle', badge: count(Booster.shuffle), accent: AppColors.purple, onTap: () => onBooster(Booster.shuffle)),
        _BoosterButton(icon: Icons.refresh_rounded, label: 'Restart', onTap: onRestart),
      ]),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({required this.icon, required this.label, required this.onTap, this.badge, this.accent = AppColors.textPrimary, this.enabled = true, this.busy = false});

  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  final Color accent;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: enabled ? onTap : null,
      semanticLabel: '$label${badge != null && badge != '+' ? ', $badge left' : ''}',
      child: SizedBox(
        width: 62,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.glass,
                border: Border.all(color: accent.withValues(alpha: accent == AppColors.textPrimary ? 0.16 : 0.35)),
              ),
              child: busy
                  ? Padding(padding: const EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2.4, color: accent))
                  : Icon(icon, color: accent, size: 26),
            ),
            if (badge != null)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: badge == '+' ? AppColors.goldGradient : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Text(badge!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF061021))),
                ),
              ),
          ]),
          const SizedBox(height: 5),
          Text(label, style: AppText.small.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
