import 'dart:io';

/// Store identifiers & URLs used for app rating and sharing.
///
/// TODO(after ASC app creation): set [appStoreId] to the numeric Apple App
/// Store ID. Until then the App Store URL is omitted (rating falls back to the
/// native in-app review prompt).
class StoreLinks {
  StoreLinks._();

  /// Numeric Apple App Store ID, e.g. "1234567890". Empty until published.
  static const String appStoreId = '';

  /// Android applicationId (see android/app/build.gradle → applicationId).
  static const String androidPackage = 'com.example.manage_subscription';

  /// TODO(いずれ Android 配布を始めるとき): Google Play にも出すことになったら
  /// これを true にする。今は iOS(App Store) のみ配布予定なので、共有は App Store
  /// だけを出す（[shareLinks] / [shareUrl] がこのフラグで分岐）。true にしたら、
  /// 受信者OSで振り分ける [smartLink]（下記）もセットするのが望ましい。
  static const bool androidDistribution = false;

  /// A single OS-detecting redirect page (host on GitHub Pages). Only relevant
  /// once [androidDistribution] is true: sharing ONE url lets the recipient's
  /// own device pick the store (iOS→App Store, Android→Google Play). A plain
  /// shared link can't adapt to the recipient's OS by itself — this redirect
  /// page is what makes it work.
  ///
  /// TODO(after hosting): set to e.g.
  /// 'https://murakami-kaito-dev.github.io/submana-legal/download.html'
  static const String smartLink = '';

  static bool get hasSmartLink => smartLink.isNotEmpty;

  static bool get hasAppStoreId => appStoreId.isNotEmpty;

  static String? get iosUrl =>
      hasAppStoreId ? 'https://apps.apple.com/app/id$appStoreId' : null;

  static String get androidUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackage';

  /// The listing URL for the running platform (null on iOS until the App Store
  /// ID is set).
  static String? get currentPlatformUrl => Platform.isIOS ? iosUrl : androidUrl;

  /// Store links block for share messages. iOS-only for now; Google Play is
  /// added once [androidDistribution] is turned on.
  static String shareLinks() {
    final lines = <String>[];
    if (iosUrl != null) lines.add('App Store: ${iosUrl!}');
    if (androidDistribution) lines.add('Google Play: $androidUrl');
    return lines.join('\n');
  }

  /// What to drop into a share message.
  /// - iOS-only (now): the App Store URL (empty until [appStoreId] is set).
  /// - Multi-store (later): the OS-detecting [smartLink] so the recipient's
  ///   device picks the right store.
  static String shareUrl() {
    if (androidDistribution && hasSmartLink) return smartLink;
    return iosUrl ?? shareLinks();
  }
}
