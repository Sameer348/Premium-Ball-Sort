import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/game_themes.dart';
import '../../core/utils/transitions.dart';
import '../../models/game_mode.dart';
import '../../services/ads/admob_service.dart';
import '../../services/ads/banner_ad_widget.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/buttons.dart';
import '../../widgets/coin_pill.dart';
import '../../widgets/pressable.dart';
import '../achievements/achievements_screen.dart';
import '../daily/daily_reward_sheet.dart';
import '../daily/daily_screen.dart';
import '../gameplay/game_launcher.dart';
import '../levels/level_map_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _rewardOffered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || _rewardOffered) return;
      _rewardOffered = true;
      if (context.read<ProgressController>().claimableRewardIndex != null) {
        await showDailyRewardSheet(context);
      }
    });
  }

  void _open(Widget page) => Navigator.of(context).push(Transitions.slide(page));

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final v = p.value;
    final reduce = context.select<SettingsController, bool>((s) => s.value.reduceMotion);
    final theme = GameThemeSpec.of(v.theme);
    final rewardReady = p.claimableRewardIndex != null;
    final dailyDone = p.todaysDaily.completed;

    return Scaffold(
      body: AnimatedBackground(
        theme: theme,
        reduceMotion: reduce,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            // ---- top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                _ProfileChip(level: v.currentLevel, stars: v.totalStars, onTap: () => _open(const AchievementsScreen())),
                const Spacer(),
                CoinPill(onTap: () => _open(const ShopScreen(initialTab: 3))),
                const SizedBox(width: 10),
                IconCircleButton(icon: Icons.settings_rounded, label: 'Settings', onTap: () => _open(const SettingsScreen())),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final compact = c.maxHeight < 560;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(height: compact ? 8 : 20),
                          AppLogo(size: compact ? 0.8 : 1, animate: !reduce),
                          SizedBox(height: compact ? 20 : 40),
                          GradientButton(
                            label: 'CONTINUE',
                            subtitle: 'Level ${v.currentLevel}',
                            icon: Icons.play_arrow_rounded,
                            height: 72,
                            pulse: !reduce,
                            onTap: () => GameLauncher.play(context, mode: GameMode.classic),
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: GlassButton(label: 'PLAY', icon: Icons.map_rounded, onTap: () => _open(const LevelMapScreen()))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Stack(clipBehavior: Clip.none, children: [
                                GlassButton(label: 'DAILY', icon: Icons.today_rounded, accent: AppColors.gold, onTap: () => _open(const DailyScreen())),
                                if (!dailyDone) const Positioned(right: 10, top: -3, child: _Dot(color: AppColors.gold)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 22),
                          Align(alignment: Alignment.centerLeft, child: Text('MORE MODES', style: AppText.label)),
                          const SizedBox(height: 10),
                          Row(children: [
                            _ModeCard(icon: Icons.all_inclusive_rounded, label: 'Endless', color: AppColors.cyan, sub: 'Best ${v.endlessBest}', onTap: () => GameLauncher.play(context, mode: GameMode.endless)),
                            const SizedBox(width: 10),
                            _ModeCard(icon: Icons.timer_rounded, label: 'Time Attack', color: AppColors.amber, sub: v.timeAttackBest > 0 ? 'Best ${v.timeAttackBest}' : 'Beat the clock', onTap: () => GameLauncher.play(context, mode: GameMode.timeAttack)),
                            const SizedBox(width: 10),
                            _ModeCard(icon: Icons.diamond_rounded, label: 'Perfect', color: AppColors.violet, sub: 'Move-limited', onTap: () => GameLauncher.play(context, mode: GameMode.perfect)),
                          ]),
                          const SizedBox(height: 20),
                          if (rewardReady)
                            Pressable(
                              onTap: () => showDailyRewardSheet(context),
                              semanticLabel: 'Claim daily reward',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: AppColors.gold.withValues(alpha: 0.08),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.card_giftcard_rounded, color: AppColors.gold),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Your daily reward is ready', style: AppText.h3.copyWith(fontSize: 15))),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
                                ]),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
            ),
            // ---- bottom nav
            _BottomNav(
              onShop: () => _open(const ShopScreen()),
              onThemes: () => _open(const ShopScreen(initialTab: 2)),
              onAchievements: () => _open(const AchievementsScreen()),
              onMap: () => _open(const LevelMapScreen()),
            ),
            const BannerAdWidget(),
            if (!context.select<AdMobService, bool>((a) => a.bannersAllowed)) SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ]),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.level, required this.stars, required this.onTap});
  final int level;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: 'Profile, level $level, $stars stars',
        child: Container(
          height: 44,
          padding: const EdgeInsets.only(left: 4, right: 14),
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.glassBorder)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: const Icon(Icons.person_rounded, color: Color(0xFF061021), size: 22),
            ),
            const SizedBox(width: 8),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LV $level', style: AppText.number.copyWith(fontSize: 13)),
              Row(children: [
                const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                Text(' $stars', style: AppText.small.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gold)),
              ]),
            ]),
          ]),
        ),
      );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Pressable(
          onTap: onTap,
          semanticLabel: label,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.glass,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.copyWith(fontSize: 11)),
            ]),
          ),
        ),
      );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onShop, required this.onThemes, required this.onAchievements, required this.onMap});
  final VoidCallback onShop;
  final VoidCallback onThemes;
  final VoidCallback onAchievements;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String l, VoidCallback t, Color c) => Expanded(
          child: Pressable(
            onTap: t,
            semanticLabel: l,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(i, color: c, size: 26),
                const SizedBox(height: 4),
                Text(l, style: AppText.small.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(children: [
        item(Icons.storefront_rounded, 'Shop', onShop, AppColors.gold),
        item(Icons.palette_rounded, 'Themes', onThemes, AppColors.purple),
        item(Icons.emoji_events_rounded, 'Awards', onAchievements, AppColors.violet),
        item(Icons.route_rounded, 'Levels', onMap, AppColors.cyan),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]),
      );
}
