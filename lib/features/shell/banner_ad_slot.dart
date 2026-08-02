import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/core_providers.dart';
import '../../providers/premium_provider.dart';

/// The fixed bottom banner. Free tier only — premium removes it entirely
/// (returns a zero-size box). Renders a soft placeholder while/if the ad fails
/// to load so the layout never jumps.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (ref.read(premiumProvider)) return;
    final service = ref.read(adServiceProvider);
    if (!service.isReady) return;
    final ad = service.createBanner(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _loaded = false);
      },
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    if (isPremium) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        width: double.infinity,
        alignment: Alignment.center,
        color: AppColors.canvas,
        child: _loaded && _ad != null
            ? SizedBox(
                width: _ad!.size.width.toDouble(),
                height: _ad!.size.height.toDouble(),
                child: AdWidget(ad: _ad!),
              )
            : const _Placeholder(),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Text(
        'ⓘ 広告  —  プレミアムで非表示',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }
}
