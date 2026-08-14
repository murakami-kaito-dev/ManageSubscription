// 【広告は全面的に無効化（コメントアウト）】2026-08-14
//
// このアプリは広告を出さない方針。将来また入れる可能性があるので、削除ではなく
// コメントアウトで残してある。復活させる手順は以下の5か所を戻すだけ:
//   1. pubspec.yaml の `google_mobile_ads` の行
//   2. このファイル全体
//   3. lib/features/shell/banner_ad_slot.dart 全体
//   4. lib/features/shell/home_shell.dart の import と `const BannerAdSlot()`
//   5. lib/providers/core_providers.dart の import と adServiceProvider、
//      lib/main.dart の import と AdService.init() 呼び出し
// 戻したら `kAdsEnabled` を true にし、テスト用ではない本番の広告ユニットIDに
// 差し替えること。ios/Runner/Info.plist の GADApplicationIdentifier も要更新。

/*
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

*/
