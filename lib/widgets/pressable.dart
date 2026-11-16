import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio/audio_service.dart';
import '../services/haptics/haptics_service.dart';

/// Spring scale-on-press wrapper with sound + haptic. Large hit area and
/// semantics for accessibility.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.semanticLabel, this.scale = 0.94, this.sound = true});

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double scale;
  final bool sound;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 90), reverseDuration: const Duration(milliseconds: 260));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _c.forward() : null,
        onTapCancel: enabled ? () => _c.reverse() : null,
        onTapUp: enabled
            ? (_) {
                _c.reverse();
                if (widget.sound) context.read<AudioService>().play(Sfx.button, volume: 0.5);
                context.read<HapticsService>().button();
                widget.onTap!();
              }
            : null,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final t = Curves.easeOut.transform(_c.value);
            return Transform.scale(scale: 1 - (1 - widget.scale) * t, child: child);
          },
          child: Opacity(opacity: enabled ? 1 : 0.45, child: widget.child),
        ),
      ),
    );
  }
}
