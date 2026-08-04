import 'package:flutter/material.dart';

import '../../data/models/subscription.dart';
import '../theme/app_typography.dart';
import '../utils/image_paths.dart';

/// The single source of truth for how a subscription is shown as a small
/// avatar, identically on every tab (home / analytics / calendar / history):
/// the custom image / emoji / initial in the centre, ringed and tinted with
/// **that subscription's own color** (`sub.color`) — NOT the global theme
/// color — so each item keeps its individual identity everywhere.
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
    final file = ImagePaths.resolve(sub.imagePath);
    final hasImage = file != null && file.existsSync();

    // Derive a soft background tint and a darker glyph color from the item's
    // own color, mirroring how AppAccent derives its trio.
    final base = sub.color;
    final hsl = HSLColor.fromColor(base);
    final deep =
        hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    final soft = hsl
        .withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.32).clamp(0.0, 0.94))
        .toColor();

    final ring = (size * 0.05).clamp(1.6, 3.0);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      // Clip the CONTENT (image/tint) to the rounded rect so a square image's
      // corners can never poke outside the frame.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hasImage ? null : soft,
        borderRadius: BorderRadius.circular(radius),
      ),
      // The colored ring is painted ON TOP of the (already-clipped) content, so
      // it frames the image edge-to-edge on every side including the corners.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: base, width: ring.toDouble()),
      ),
      child: hasImage
          ? Image.file(file, fit: BoxFit.cover, width: size, height: size)
          : (sub.emoji != null && sub.emoji!.trim().isNotEmpty
              ? Text(sub.emoji!.trim(),
                  style: TextStyle(fontSize: size * 0.48))
              : Text(
                  sub.displayGlyph.toUpperCase(),
                  style: AppType.display(size * 0.44,
                      weight: FontWeight.w800, color: deep),
                )),
    );
  }
}
