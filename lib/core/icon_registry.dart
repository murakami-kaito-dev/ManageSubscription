import 'package:flutter/material.dart';

/// A fixed registry of selectable icons.
///
/// Icons are stored in the DB as codepoints, but building `IconData(codepoint)`
/// at runtime defeats Flutter's icon tree-shaking (and would force
/// `--no-tree-shake-icons` on every release build). Instead we keep every
/// selectable icon as a **const** `IconData` here and resolve a stored
/// codepoint back to its const instance via [resolve]. That keeps release
/// builds tree-shakeable with no special flags.
class IconRegistry {
  IconRegistry._();

  /// Icons offered when creating a category.
  static const List<IconData> categoryIcons = [
    Icons.movie_rounded,
    Icons.work_rounded,
    Icons.spa_rounded,
    Icons.music_note_rounded,
    Icons.sports_esports_rounded,
    Icons.fitness_center_rounded,
    Icons.book_rounded,
    Icons.cloud_rounded,
    Icons.shopping_bag_rounded,
    Icons.pets_rounded,
    Icons.restaurant_rounded,
    Icons.school_rounded,
    Icons.newspaper_rounded,
    Icons.smart_toy_rounded,
    Icons.home_rounded,
  ];

  /// Icons offered when creating a payment method.
  static const List<IconData> paymentIcons = [
    Icons.credit_card_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.account_balance_rounded,
    Icons.phone_iphone_rounded,
    Icons.paid_rounded,
    Icons.qr_code_rounded,
    Icons.savings_rounded,
    Icons.currency_yen_rounded,
    Icons.apple_rounded,
    Icons.shop_rounded,
  ];

  static const IconData fallbackCategory = Icons.category_rounded;
  static const IconData fallbackPayment = Icons.account_balance_wallet_rounded;

  /// codepoint -> const IconData, built once from the lists above.
  static final Map<int, IconData> _byCodePoint = {
    for (final i in [...categoryIcons, ...paymentIcons]) i.codePoint: i,
  };

  static IconData resolve(int codePoint, {IconData? fallback}) =>
      _byCodePoint[codePoint] ?? fallback ?? fallbackCategory;
}
