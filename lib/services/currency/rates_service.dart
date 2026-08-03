import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/currency.dart';

/// Fetches the day's FX rates (to JPY) and caches them so cross-currency totals
/// use up-to-date numbers. Free, no API key required (open.er-api.com).
class RatesService {
  RatesService(this._prefs);
  final SharedPreferences _prefs;

  static const _kRates = 'fx_rates_json';
  static const _kDate = 'fx_rates_date';

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Loads cached rates into [CurrencyRates] immediately, then refreshes from
  /// the network when the cache isn't today's. Best-effort — never throws.
  Future<void> load() async {
    _applyCached();
    if (_prefs.getString(_kDate) == _today) return; // already fresh
    await _refresh();
  }

  void _applyCached() {
    final raw = _prefs.getString(_kRates);
    if (raw == null) return;
    try {
      final map = (jsonDecode(raw) as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()));
      CurrencyRates.update(map, date: _prefs.getString(_kDate));
    } catch (_) {/* keep fallbacks */}
  }

  Future<void> _refresh() async {
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/JPY'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rates = body['rates'] as Map<String, dynamic>?;
      if (rates == null) return;

      // API gives "X per 1 JPY"; we want "JPY per 1 X" = 1 / rate.
      final toJpy = <String, double>{'JPY': 1};
      for (final code in ['USD', 'EUR', 'GBP']) {
        final r = (rates[code] as num?)?.toDouble();
        if (r != null && r > 0) toJpy[code] = 1 / r;
      }
      CurrencyRates.update(toJpy, date: _today);
      await _prefs.setString(_kRates, jsonEncode(toJpy));
      await _prefs.setString(_kDate, _today);
    } catch (e) {
      debugPrint('FX refresh skipped: $e');
    }
  }
}
