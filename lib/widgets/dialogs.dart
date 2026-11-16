import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Premium modal card used for every in-game dialog.
Future<T?> showGlassDialog<T>(BuildContext context, {required Widget Function(BuildContext) builder, bool dismissible = true}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Close',
    barrierColor: const Color(0xB3040814),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 20))],
                ),
                child: builder(ctx),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(c), child: child));
    },
  );
}

class DialogHeader extends StatelessWidget {
  const DialogHeader({super.key, required this.icon, required this.title, this.subtitle, this.color = AppColors.cyan});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24)],
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 14),
        Text(title, style: AppText.h2, textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: AppText.body, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 18),
      ]);
}

void showToast(BuildContext context, String message, {Color color = AppColors.card}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(milliseconds: 1800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
}
