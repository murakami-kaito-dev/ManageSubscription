import 'package:flutter/material.dart';

/// Counts up from the previous value to the new one whenever [value] changes
/// (per the animation-effects skill). Formats via [formatter].
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.easeOutQuart,
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, v, _) => Text(formatter(v), style: style),
    );
  }
}
