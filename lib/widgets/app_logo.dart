import 'package:flutter/material.dart';

import '../core/constants/app_info.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'ball_icon.dart';

/// Original wordmark: three orbiting balls + rounded heavy type with a
/// cyan→blue gradient accent. Name comes from [AppInfo].
class AppLogo extends StatefulWidget {
  const AppLogo({super.key, this.size = 1, this.animate = true});
  final double size;
  final bool animate;

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      label: AppInfo.name,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return SizedBox(
              width: 150 * s,
              height: 84 * s,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 120 * s,
                  height: 50 * s,
                  decoration: BoxDecoration(boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.18), blurRadius: 50 * s, spreadRadius: 6 * s)]),
                ),
                Positioned(left: 22 * s, top: (24 - t * 6) * s, child: BallIcon(size: 40 * s, color: 0)),
                Positioned(top: (4 + t * 5) * s, child: BallIcon(size: 56 * s, color: 1)),
                Positioned(right: 22 * s, top: (26 - (1 - t) * 6) * s, child: BallIcon(size: 40 * s, color: 3)),
              ]),
            );
          },
        ),
        SizedBox(height: 6 * s),
        Text(AppInfo.wordA, style: AppText.display.copyWith(fontSize: 44 * s, letterSpacing: 12 * s, height: 1)),
        ShaderMask(
          shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
          child: Text(AppInfo.wordB, style: AppText.display.copyWith(fontSize: 30 * s, letterSpacing: 14 * s, color: Colors.white, height: 1.1)),
        ),
      ]),
    );
  }
}
