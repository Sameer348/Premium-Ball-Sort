import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/game_themes.dart';
import '../../models/booster.dart';
import '../../models/cosmetics.dart';
import '../../services/ads/ad_config.dart';
import '../../services/ads/admob_service.dart';
import '../../services/audio/audio_service.dart';
import '../../state/progress_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/coin_pill.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_scaffold.dart';
import '../gameplay/widgets/game_dialogs.dart';
import 'mini_preview.dart';

/// Cosmetics + boosters. Everything is cosmetic or a convenience — never
/// required to progress.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Shop',
      banner: true,
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 44,
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(22)),
          child: TabBar(
            controller: _tabs,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22)),
            labelColor: const Color(0xFF061021),
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [Tab(text: 'Balls'), Tab(text: 'Tubes'), Tab(text: 'Themes'), Tab(text: 'Boosters')],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(controller: _tabs, children: const [_BallsTab(), _TubesTab(), _ThemesTab(), _BoostersTab()]),
        ),
      ]),
    );
  }
}

Future<void> _purchase(BuildContext context, {required String id, required String name, required int price, required VoidCallback select}) async {
  final p = context.read<ProgressController>();
  if (p.value.owns(id)) {
    select();
    context.read<AudioService>().play(Sfx.select);
    return;
  }
  if (p.coins < price) {
    showToast(context, 'You need ${price - p.coins} more coins.', color: AppColors.coral.withValues(alpha: 0.9));
    return;
  }
  final ok = await showGlassDialog<bool>(context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        DialogHeader(icon: Icons.lock_open_rounded, title: 'Unlock $name?', subtitle: 'Purely cosmetic — enjoy the look.', color: AppColors.violet),
        GradientButton(label: 'UNLOCK · $price', icon: Icons.toll_rounded, gradient: AppColors.goldGradient, height: 56, onTap: () => Navigator.pop(ctx, true)),
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.textMuted))),
      ]));
  if (ok != true || !context.mounted) return;
  if (p.buyItem(id, price)) {
    select();
    context.read<AudioService>().play(Sfx.achievement, volume: 0.6);
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => GridView.count(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          crossAxisCount: c.maxWidth > 600 ? 3 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
          children: children,
        ),
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.name, required this.price, required this.owned, required this.selected, required this.premium, required this.preview, required this.onTap});

  final String name;
  final int price;
  final bool owned;
  final bool selected;
  final bool premium;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.cyan : (premium ? AppColors.violet : AppColors.glassBorder);
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      semanticLabel: '$name, ${selected ? 'selected' : owned ? 'owned' : '$price coins'}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: AppColors.surface,
          border: Border.all(color: accent.withValues(alpha: selected ? 0.9 : 0.5), width: selected ? 2 : 1),
          boxShadow: [if (selected) BoxShadow(color: AppColors.cyan.withValues(alpha: 0.25), blurRadius: 18)],
        ),
        child: Column(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              child: Stack(fit: StackFit.expand, children: [
                Container(color: AppColors.secondary),
                Padding(padding: const EdgeInsets.all(8), child: preview),
                if (premium)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(gradient: AppColors.premiumGradient, borderRadius: BorderRadius.circular(8)),
                      child: const Text('PREMIUM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(fontSize: 14)),
              const SizedBox(height: 6),
              if (selected)
                _Tag(icon: Icons.check_circle_rounded, text: 'SELECTED', color: AppColors.cyan)
              else if (owned)
                _Tag(icon: Icons.touch_app_rounded, text: 'USE', color: AppColors.success)
              else
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const CoinGlyph(size: 18),
                  const SizedBox(width: 5),
                  Text('$price', style: AppText.number.copyWith(color: AppColors.gold)),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: AppText.label.copyWith(color: color, fontSize: 11)),
        ]),
      );
}

class _BallsTab extends StatelessWidget {
  const _BallsTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final v = p.value;
    final theme = GameThemeSpec.of(v.theme);
    return _Grid(children: [
      for (final s in BallSkin.values)
        _ItemCard(
          name: s.label,
          price: s.price,
          owned: v.owns(s.id),
          selected: v.ballSkin == s,
          premium: s.premium,
          preview: MiniPreview(ballSkin: s, tubeSkin: v.tubeSkin, theme: theme),
          onTap: () => _purchase(context, id: s.id, name: s.label, price: s.price, select: () => p.selectBallSkin(s)),
        ),
    ]);
  }
}

class _TubesTab extends StatelessWidget {
  const _TubesTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final v = p.value;
    final theme = GameThemeSpec.of(v.theme);
    return _Grid(children: [
      for (final s in TubeSkin.values)
        _ItemCard(
          name: s.label,
          price: s.price,
          owned: v.owns(s.id),
          selected: v.tubeSkin == s,
          premium: s.premium,
          preview: MiniPreview(ballSkin: v.ballSkin, tubeSkin: s, theme: theme),
          onTap: () => _purchase(context, id: s.id, name: s.label, price: s.price, select: () => p.selectTubeSkin(s)),
        ),
    ]);
  }
}

class _ThemesTab extends StatelessWidget {
  const _ThemesTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final v = p.value;
    return _Grid(children: [
      for (final t in ThemeId.values)
        _ItemCard(
          name: t.label,
          price: t.price,
          owned: v.owns(t.id),
          selected: v.theme == t,
          premium: t.premium,
          preview: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: MiniPreview(ballSkin: v.ballSkin, tubeSkin: v.tubeSkin, theme: GameThemeSpec.of(t), showBackground: true),
          ),
          onTap: () => _purchase(context, id: t.id, name: t.label, price: t.price, select: () => p.selectTheme(t)),
        ),
    ]);
  }
}

class _BoostersTab extends StatelessWidget {
  const _BoostersTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>();
    final ads = context.watch<AdMobService>();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [AppColors.violet.withValues(alpha: 0.25), AppColors.blue.withValues(alpha: 0.12)]),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          const Icon(Icons.play_circle_fill_rounded, color: AppColors.purple, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Free coins', style: AppText.h3),
              Text('Watch a short ad → ${AdConfig.rewardedCoins} coins', style: AppText.small),
            ]),
          ),
          SizedBox(
            width: 96,
            child: GradientButton(
              label: 'WATCH',
              height: 44,
              gradient: AppColors.premiumGradient,
              textColor: Colors.white,
              onTap: ads.ready
                  ? () async {
                      final earned = await ads.showRewarded(placement: 'shop_coins');
                      if (!context.mounted) return;
                      if (earned) {
                        p.addCoins(AdConfig.rewardedCoins);
                        context.read<AudioService>().play(Sfx.coin);
                      } else {
                        showToast(context, 'No ad available right now.');
                      }
                    }
                  : null,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      for (final b in Booster.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.glassBorder)),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: boosterColor(b).withValues(alpha: 0.14)),
                child: Icon(boosterIcon(b), color: boosterColor(b), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${b.label}  ·  ${p.inventory(b)} owned', style: AppText.h3.copyWith(fontSize: 15)),
                  Text(b.description, style: AppText.small),
                ]),
              ),
              _BuyChip(count: 1, price: ProgressController.priceOf(b), onTap: () => _buy(context, b, 1)),
              const SizedBox(width: 6),
              _BuyChip(count: 5, price: (ProgressController.priceOf(b) * 4.5).round(), onTap: () => _buy(context, b, 5)),
            ]),
          ),
        ),
    ]);
  }

  void _buy(BuildContext context, Booster b, int n) {
    final p = context.read<ProgressController>();
    final price = n == 1 ? ProgressController.priceOf(b) : (ProgressController.priceOf(b) * 4.5).round();
    if (!p.spendCoins(price)) {
      showToast(context, 'Not enough coins.', color: AppColors.coral.withValues(alpha: 0.9));
      return;
    }
    p.grantBooster(b, n);
    context.read<AudioService>().play(Sfx.coin);
  }
}

class _BuyChip extends StatelessWidget {
  const _BuyChip({required this.count, required this.price, required this.onTap});
  final int count;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: 'Buy $count for $price coins',
        child: Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.gold.withValues(alpha: 0.1), border: Border.all(color: AppColors.gold.withValues(alpha: 0.35))),
          child: Column(children: [
            Text('×$count', style: AppText.h3.copyWith(fontSize: 14)),
            Text('$price', style: AppText.small.copyWith(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
        ),
      );
}
