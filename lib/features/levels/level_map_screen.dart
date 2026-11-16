import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../game/levels/level_catalog.dart';
import '../../models/game_mode.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_scaffold.dart';
import '../gameplay/game_launcher.dart';

/// Winding journey map, level 1 at the bottom. Lazily built, so 2000
/// levels cost nothing; scrolls to the current level on open.
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> with SingleTickerProviderStateMixin {
  static const double _extent = 112;
  late final ScrollController _scroll;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    final cur = context.read<ProgressController>().value.currentLevel;
    _scroll = ScrollController(initialScrollOffset: math.max(0, (cur - 3) * _extent));
    if (!context.read<SettingsController>().value.reduceMotion) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>().value;
    return ScreenScaffold(
      title: 'Journey',
      banner: true,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Row(children: [
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: 4),
          Text('${p.totalStars}', style: AppText.number.copyWith(color: AppColors.gold)),
        ]),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return ListView.builder(
          controller: _scroll,
          reverse: true,
          itemExtent: _extent,
          padding: const EdgeInsets.symmetric(vertical: 40),
          itemCount: LevelCatalog.totalLevels,
          itemBuilder: (context, i) {
            final level = i + 1;
            final stars = p.stars[level] ?? 0;
            final unlocked = level <= p.currentLevel;
            final current = level == p.currentLevel;
            return _MapRow(
              level: level,
              width: w,
              x: _xFor(i, w),
              nextX: _xFor(i + 1, w),
              stars: stars,
              unlocked: unlocked,
              current: current,
              pulse: _pulse,
              onTap: () {
                if (unlocked) {
                  GameLauncher.play(context, mode: GameMode.classic, level: level);
                } else {
                  showToast(context, 'Finish level ${p.currentLevel} to unlock more.');
                }
              },
            );
          },
        );
      }),
    );
  }

  static double _xFor(int i, double w) => w / 2 + math.sin(i * 0.85) * w * 0.26;
}

class _MapRow extends StatelessWidget {
  const _MapRow({
    required this.level,
    required this.width,
    required this.x,
    required this.nextX,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.pulse,
    required this.onTap,
  });

  final int level;
  final double width;
  final double x;
  final double nextX;
  final int stars;
  final bool unlocked;
  final bool current;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diff = LevelCatalog.difficultyFor(level);
    final bandStart = level == 1 || LevelCatalog.difficultyFor(level - 1) != diff;
    final size = current ? 74.0 : 60.0;
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: CustomPaint(painter: _PathPainter(x: x, nextX: nextX, done: level < 1 || stars > 0, extent: 112)),
      ),
      if (bandStart && level <= 50)
        Positioned(
          left: x < width / 2 ? x + 50 : null,
          right: x >= width / 2 ? width - x + 50 : null,
          top: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.glassBorder)),
            child: Text(diff.label.toUpperCase(), style: AppText.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
          ),
        ),
      Positioned(
        left: x - size / 2,
        top: 112 / 2 - size / 2,
        child: Pressable(
          onTap: onTap,
          semanticLabel: 'Level $level${unlocked ? ', $stars stars' : ', locked'}',
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, child) {
              final t = current ? pulse.value : 0.0;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: current
                      ? AppColors.primaryGradient
                      : unlocked
                          ? const LinearGradient(colors: [AppColors.card, AppColors.elevated], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : null,
                  color: unlocked ? null : AppColors.secondary,
                  border: Border.all(
                    color: current
                        ? Colors.white.withValues(alpha: 0.6)
                        : stars > 0
                            ? AppColors.success.withValues(alpha: 0.55)
                            : AppColors.glassBorder,
                    width: current ? 3 : 1.5,
                  ),
                  boxShadow: [
                    if (current) BoxShadow(color: AppColors.cyan.withValues(alpha: 0.35 + t * 0.3), blurRadius: 20 + t * 16, spreadRadius: t * 4),
                    if (stars > 0 && !current) BoxShadow(color: AppColors.success.withValues(alpha: 0.18), blurRadius: 14),
                    const BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 6)),
                  ],
                ),
                child: child,
              );
            },
            child: Center(
              child: unlocked
                  ? Text('$level', style: AppText.h3.copyWith(fontSize: current ? 22 : 18, color: current ? const Color(0xFF061021) : AppColors.textPrimary))
                  : const Icon(Icons.lock_rounded, color: AppColors.textDisabled, size: 22),
            ),
          ),
        ),
      ),
      if (unlocked && !current)
        Positioned(
          left: x - 30,
          top: 112 / 2 + size / 2 - 8,
          width: 60,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var s = 0; s < 3; s++)
              Icon(Icons.star_rounded, size: s == 1 ? 18 : 15, color: s < stars ? AppColors.gold : AppColors.textDisabled.withValues(alpha: 0.6)),
          ]),
        ),
    ]);
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.x, required this.nextX, required this.done, required this.extent});
  final double x;
  final double nextX;
  final bool done;
  final double extent;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final ny = y - extent;
    final path = Path()
      ..moveTo(x, y)
      ..cubicTo(x, y - extent * 0.5, nextX, ny + extent * 0.5, nextX, ny);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = AppColors.surface,
    );
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = done ? AppColors.cyan.withValues(alpha: 0.55) : AppColors.textDisabled.withValues(alpha: 0.35);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 14) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.x != x || old.nextX != nextX || old.done != done;
}
