import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Banner-ad helper. Uses Google's official *test* ad unit IDs so ads render in
/// development without a real AdMob account; swap in production unit IDs before
/// release. Premium hides all ads (the banner slot simply isn't built).
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  // Google-provided test unit IDs.
  static const String _androidTestBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBanner =
      'ca-app-pub-3940256099942544/2934735716';

  String get bannerUnitId =>
      Platform.isIOS ? _iosTestBanner : _androidTestBanner;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdMob init skipped: $e');
    }
  }

  bool get isReady => _initialized;

  BannerAd createBanner({required VoidCallback onLoaded, required VoidCallback onFailed}) {
    return BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          onFailed();
        },
      ),
    );
  }
}
