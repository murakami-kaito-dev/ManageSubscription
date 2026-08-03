import 'package:intl/intl.dart';

/// Date formatting helpers shared across screens.
class JpDate {
  JpDate._();

  /// "M月d日" for the current year, "yyyy年M月d日" otherwise — so dates in other
  /// years are unambiguous at a glance.
  static String short(DateTime date, {DateTime? now}) {
    final y = (now ?? DateTime.now()).year;
    return date.year == y
        ? DateFormat('M月d日').format(date)
        : DateFormat('yyyy年M月d日').format(date);
  }
}
