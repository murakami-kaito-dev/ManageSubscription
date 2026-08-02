import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable tap micro-interaction (per the animation-effects skill): every
/// primary surface squishes to ~0.96 on press with spring physics and pops
/// back, paired with a light haptic. Keep this the single source of that feel.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    lowerBound: 0,
    upperBound: 1,
  );

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _down(_) {
    if (!_interactive) return;
    _c.forward();
  }

  void _up([_]) {
    if (!_interactive) return;
    _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _up,
      onTap: _interactive
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_c.value);
          return Transform.scale(
            scale: 1 - (1 - widget.scale) * t,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
