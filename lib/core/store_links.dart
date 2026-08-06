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

  static bool get hasAppStoreId => appStoreId.isNotEmpty;

  static String? get iosUrl =>
      hasAppStoreId ? 'https://apps.apple.com/app/id$appStoreId' : null;

  static String get androidUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackage';

  /// The listing URL for the running platform (null on iOS until the App Store
  /// ID is set).
  static String? get currentPlatformUrl => Platform.isIOS ? iosUrl : androidUrl;

  /// Store links block for share messages. Includes whichever URLs are known.
  static String shareLinks() {
    final lines = <String>[];
    if (iosUrl != null) lines.add('App Store: ${iosUrl!}');
    lines.add('Google Play: $androidUrl');
    return lines.join('\n');
  }
}
