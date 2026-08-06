import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/store_links.dart';

/// App-rating helper: opens the store review flow and remembers whether the
/// one-time "first add" review prompt has been shown.
class RatingService {
  RatingService(this._prefs);
  final SharedPreferences _prefs;

  static const _kFirstAddPromptShown = 'rating_first_add_prompt_shown';
  final InAppReview _review = InAppReview.instance;

  /// Whether the review prompt shown after the user's first self-added item has
  /// already been displayed (so it only ever appears once).
  bool get firstAddPromptShown =>
      _prefs.getBool(_kFirstAddPromptShown) ?? false;

  Future<void> markFirstAddPromptShown() =>
      _prefs.setBool(_kFirstAddPromptShown, true);

  /// Opens the rating flow: prefers the native in-app review prompt, falling
  /// back to the store listing. Best-effort — never throws.
  Future<void> rate() async {
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
        return;
      }
    } catch (_) {/* fall through to the store listing */}
    try {
      if (StoreLinks.hasAppStoreId) {
        await _review.openStoreListing(appStoreId: StoreLinks.appStoreId);
      } else {
        await _review.openStoreListing();
      }
    } catch (_) {/* nothing more we can do */}
  }
}
