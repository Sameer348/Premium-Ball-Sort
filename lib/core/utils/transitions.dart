import 'package:flutter/material.dart';

/// Custom route transitions (no default platform slide).
class Transitions {
  Transitions._();

  static bool reduceMotion = false;

  static Duration get _d => Duration(milliseconds: reduceMotion ? 160 : 420);

  /// Home → Levels, Shop, Settings: slide + fade.
  static Route<T> slide<T>(Widget page, {bool fromRight = true}) => PageRouteBuilder<T>(
        transitionDuration: _d,
        reverseTransitionDuration: _d,
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, a, _, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
          return FadeTransition(
            opacity: c,
            child: reduceMotion
                ? child
                : SlideTransition(
                    position: Tween(begin: Offset(fromRight ? 0.12 : 0, fromRight ? 0 : 0.08), end: Offset.zero).animate(c),
                    child: child,
                  ),
          );
        },
      );

  /// Levels → Game: zoom + fade.
  static Route<T> zoom<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: _d,
        reverseTransitionDuration: _d,
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, a, _, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
          return FadeTransition(
            opacity: c,
            child: reduceMotion ? child : ScaleTransition(scale: Tween(begin: 1.08, end: 1.0).animate(c), child: child),
          );
        },
      );

  /// Game → Complete: scale + fade over the board (transparent route).
  static Route<T> overlay<T>(Widget page) => PageRouteBuilder<T>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: _d,
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, a, _, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
          return FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: reduceMotion ? child : ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(c), child: child),
          );
        },
      );
}
