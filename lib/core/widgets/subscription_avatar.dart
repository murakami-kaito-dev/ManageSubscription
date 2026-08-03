import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/subscription.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The single source of truth for how a subscription is shown as a small
/// avatar, identically on every tab (home / analytics / calendar / history):
/// the custom image / emoji / initial in the centre, with a **theme-colored**
/// ring, and — when it's text/emoji rather than an image — a theme-colored
/// background tint.
class SubscriptionAvatar extends StatelessWidget {
  const SubscriptionAvatar({
    super.key,
    required this.sub,
    this.size = 42,
    this.radius = 13,
  });

  final Subscription sub;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        sub.imagePath != null && File(sub.imagePath!).existsSync();
    final accent = AppAccent.of(context);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hasImage ? null : accent.soft,
        borderRadius: BorderRadius.circular(radius),
        // A clear theme-colored ring around every avatar.
        border: Border.all(color: accent.primary, width: 1.6),
      ),
      child: hasImage
          ? Image.file(File(sub.imagePath!), fit: BoxFit.cover)
          : (sub.emoji != null && sub.emoji!.trim().isNotEmpty
              ? Text(sub.emoji!.trim(),
                  style: TextStyle(fontSize: size * 0.48))
              : Text(
                  sub.displayGlyph.toUpperCase(),
                  style: AppType.display(size * 0.44,
                      weight: FontWeight.w800, color: accent.deep),
                )),
    );
  }
}
