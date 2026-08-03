import 'package:intl/intl.dart';

/// Supported display currencies. Amounts are stored in each subscription's own
/// currency; the analytics layer converts to the user's main currency using
/// [CurrencyRates].
enum AppCurrency { jpy, usd, eur, gbp }

extension AppCurrencyX on AppCurrency {
  String get code => switch (this) {
        AppCurrency.jpy => 'JPY',
        AppCurrency.usd => 'USD',
        AppCurrency.eur => 'EUR',
        AppCurrency.gbp => 'GBP',
      };

  String get symbol => switch (this) {
        AppCurrency.jpy => '¥',
        AppCurrency.usd => r'$',
        AppCurrency.eur => '€',
        AppCurrency.gbp => '£',
      };

  int get decimals => this == AppCurrency.jpy ? 0 : 2;

  static AppCurrency fromCode(String? code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => AppCurrency.jpy,
    );
  }
}

/// Conversion rates to JPY. Seeded with sane fallbacks so cross-currency
/// analytics work offline, then overwritten at launch with the day's fetched
/// rates (see RatesService).
class CurrencyRates {
  CurrencyRates._();

  static const Map<String, double> _fallback = {
    'JPY': 1,
    'USD': 155.0,
    'EUR': 168.0,
    'GBP': 197.0,
  };

  static Map<String, double> _toJpy = Map.of(_fallback);

  /// The day the live rates were fetched ("yyyy-MM-dd"), or null if fallback.
  static String? asOf;

  static Map<String, double> get toJpy => _toJpy;

  /// Overwrite with fetched rates (merged onto the fallbacks).
  static void update(Map<String, double> rates, {String? date}) {
    _toJpy = {..._fallback, ...rates};
    if (date != null) asOf = date;
  }

  static double convert(double amount, String from, String to) {
    final inJpy = amount * (_toJpy[from] ?? 1);
    return inJpy / (_toJpy[to] ?? 1);
  }
}

class CurrencyFormatter {
  const CurrencyFormatter(this.currency);
  final AppCurrency currency;

  String format(num amount, {bool withSymbol = true}) {
    final f = NumberFormat.currency(
      symbol: withSymbol ? currency.symbol : '',
      decimalDigits: currency.decimals,
    );
    return f.format(amount).trim();
  }

  /// Compact form for tight spaces (e.g. ¥12.3k).
  String compact(num amount) {
    final f = NumberFormat.compactCurrency(
      symbol: currency.symbol,
      decimalDigits: currency.decimals == 0 ? 0 : 1,
    );
    return f.format(amount);
  }
}
