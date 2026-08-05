import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/core_providers.dart';
import '../../providers/premium_provider.dart';
import '../../services/ads/ad_service.dart';

/// The fixed bottom banner. Free tier only — premium removes it entirely.
/// The slot only takes up space once a real ad has actually loaded; while
/// loading or if it fails (e.g. no fill in dev), it collapses to nothing rather
/// than showing an empty gray box.
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
    if (!kAdsEnabled) return; // no ads in v1 — never create/load a banner
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
    // Nothing to show unless a real ad has loaded: no gray placeholder.
    if (isPremium || !_loaded || _ad == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        width: double.infinity,
        alignment: Alignment.center,
        color: AppColors.canvas,
        child: SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
