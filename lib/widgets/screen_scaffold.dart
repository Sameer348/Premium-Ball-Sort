import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_typography.dart';
import '../core/theme/game_themes.dart';
import '../models/cosmetics.dart';
import '../services/ads/banner_ad_widget.dart';
import '../state/progress_controller.dart';
import '../state/settings_controller.dart';
import 'animated_background.dart';
import 'buttons.dart';
import 'coin_pill.dart';

/// Standard non-gameplay page: themed backdrop, header with back button,
/// title and coins, optional bottom banner ad.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({super.key, required this.title, required this.child, this.banner = false, this.showCoins = true, this.trailing});

  final String title;
  final Widget child;
  final bool banner;
  final bool showCoins;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = GameThemeSpec.of(context.select<ProgressController, ThemeId>((p) => p.value.theme));
    final reduce = context.select<SettingsController, bool>((s) => s.value.reduceMotion);
    return Scaffold(
      body: AnimatedBackground(
        theme: theme,
        reduceMotion: reduce,
        orbs: false,
        child: SafeArea(
          bottom: !banner,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(children: [
                IconCircleButton(icon: Icons.arrow_back_ios_new_rounded, label: 'Back', onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: AppText.h2, overflow: TextOverflow.ellipsis)),
                ?trailing,
                if (showCoins) const CoinPill(),
              ]),
            ),
            Expanded(child: child),
            if (banner) const BannerAdWidget(),
          ]),
        ),
      ),
    );
  }
}
