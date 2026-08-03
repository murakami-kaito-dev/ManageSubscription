import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/subscription.dart';
import '../theme/app_typography.dart';

/// The single source of truth for how a subscription is shown as a small
/// avatar: its custom image if set, otherwise its emoji/character, otherwise
/// the name's first letter — used on home, calendar, history and analytics so
/// images appear consistently everywhere.
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
    final accent = sub.color;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hasImage ? null : accent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withOpacity(0.28), width: 1.2),
      ),
      child: hasImage
          ? Image.file(File(sub.imagePath!), fit: BoxFit.cover)
          : (sub.emoji != null && sub.emoji!.trim().isNotEmpty
              ? Text(sub.emoji!.trim(),
                  style: TextStyle(fontSize: size * 0.48))
              : Text(
                  sub.displayGlyph.toUpperCase(),
                  style: AppType.display(size * 0.44,
                      weight: FontWeight.w800, color: accent),
                )),
    );
  }
}
