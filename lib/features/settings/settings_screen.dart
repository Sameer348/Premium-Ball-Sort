import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/app_settings.dart';
import '../../services/ads/admob_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/screen_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SettingsController>();
    final s = c.value;
    void set(AppSettings n) => c.update(n);
    return ScreenScaffold(
      title: 'Settings',
      showCoins: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        const _Section('AUDIO & FEEL'),
        _Toggle(icon: Icons.music_note_rounded, title: 'Music', value: s.music, onChanged: (v) => set(s.copyWith(music: v))),
        _Toggle(icon: Icons.volume_up_rounded, title: 'Sound effects', value: s.sfx, onChanged: (v) => set(s.copyWith(sfx: v))),
        _Toggle(icon: Icons.vibration_rounded, title: 'Haptics', value: s.haptics, onChanged: (v) => set(s.copyWith(haptics: v))),
        _Toggle(icon: Icons.notifications_rounded, title: 'Daily reminders', subtitle: 'A gentle nudge for the daily puzzle', value: s.notifications, onChanged: (v) => set(s.copyWith(notifications: v))),
        const _Section('ACCESSIBILITY & DISPLAY'),
        _Toggle(icon: Icons.motion_photos_off_rounded, title: 'Reduce motion', subtitle: 'Shorter, simpler animations', value: s.reduceMotion, onChanged: (v) => set(s.copyWith(reduceMotion: v))),
        _Toggle(icon: Icons.category_rounded, title: 'Color symbols', subtitle: 'Shapes on balls so color isn’t the only cue', value: s.colorSymbols, onChanged: (v) => set(s.copyWith(colorSymbols: v))),
        _Tile(
          icon: Icons.high_quality_rounded,
          title: 'Graphics quality',
          trailing: SegmentedButton<GraphicsQuality>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.cyan,
              selectedForegroundColor: const Color(0xFF061021),
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            segments: const [ButtonSegment(value: GraphicsQuality.low, label: Text('Low')), ButtonSegment(value: GraphicsQuality.high, label: Text('High'))],
            selected: {s.graphics},
            onSelectionChanged: (v) => set(s.copyWith(graphics: v.first)),
          ),
        ),
        const _Section('PRIVACY & DATA'),
        _Tile(icon: Icons.privacy_tip_rounded, title: 'Privacy', onTap: () => _privacy(context)),
        _Tile(icon: Icons.restart_alt_rounded, title: 'Reset progress', color: AppColors.coral, onTap: () => _reset(context)),
        const _Section('ABOUT'),
        _Tile(icon: Icons.info_rounded, title: 'About ${AppInfo.name}', onTap: () => _about(context)),
        const SizedBox(height: 18),
        Center(child: Text('${AppInfo.name} v${AppInfo.version}', style: AppText.small)),
      ]),
    );
  }

  Future<void> _privacy(BuildContext context) async {
    final ads = context.read<AdMobService>();
    final required = await ads.privacyOptionsRequired();
    if (!context.mounted) return;
    await showGlassDialog<void>(context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          const DialogHeader(icon: Icons.privacy_tip_rounded, title: 'Privacy'),
          Text(AppInfo.privacyText, style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          if (required) ...[
            GlassButton(label: 'AD CONSENT OPTIONS', icon: Icons.tune_rounded, onTap: () => ads.showPrivacyOptions()),
            const SizedBox(height: 10),
          ],
          GradientButton(label: 'OK', height: 52, onTap: () => Navigator.pop(ctx)),
        ]));
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await showGlassDialog<bool>(context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          const DialogHeader(icon: Icons.warning_rounded, title: 'Reset all progress?', subtitle: 'Levels, stars, coins, items and achievements will be erased. This cannot be undone.', color: AppColors.coral),
          GradientButton(
            label: 'RESET',
            height: 54,
            gradient: const LinearGradient(colors: [AppColors.coral, Color(0xFFE04E68)]),
            textColor: Colors.white,
            onTap: () => Navigator.pop(ctx, true),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.textMuted))),
        ]));
    if (ok == true && context.mounted) {
      await context.read<ProgressController>().resetProgress();
      if (context.mounted) showToast(context, 'Progress reset.');
    }
  }

  void _about(BuildContext context) => showGlassDialog<void>(context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        const DialogHeader(icon: Icons.blur_on_rounded, title: AppInfo.name, subtitle: AppInfo.tagline),
        Text(
          'A calm color-sorting puzzle. Every level is verified solvable by a built-in solver, '
          'and hints come from that same solver. Plays fully offline.\n\nVersion ${AppInfo.version}',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        GradientButton(label: 'CLOSE', height: 52, onTap: () => Navigator.pop(ctx)),
      ]));
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
        child: Text(text, style: AppText.label),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.color = AppColors.cyan});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: onTap,
          minVerticalPadding: 12,
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.glassBorder)),
          leading: Icon(icon, color: color),
          title: Text(title, style: AppText.h3.copyWith(fontSize: 15, color: color == AppColors.coral ? AppColors.coral : AppColors.textPrimary)),
          subtitle: subtitle != null ? Text(subtitle!, style: AppText.small) : null,
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted) : null),
        ),
      );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.title, required this.value, required this.onChanged, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _Tile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.cyan,
          inactiveTrackColor: AppColors.card,
          inactiveThumbColor: AppColors.textMuted,
        ),
      );
}
