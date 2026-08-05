import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// The largest amount a single subscription may have. A realistic ceiling
/// (¥100,000,000 = 1億) that still covers any real-world plan while preventing
/// absurd values that overflow to `Infinity` and break formatting, the detail
/// screen, notifications, and the analytics chart.
const double kMaxAmount = 100000000; // 1億

/// Formats an amount field with 3-digit comma grouping as the user types, and
/// caps the integer part to [maxIntDigits] digits so a value can never grow
/// large enough to become non-finite.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter({this.maxIntDigits = 9});
  final int maxIntDigits;

  static final NumberFormat _group = NumberFormat.decimalPattern('en');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    // Only digits with at most one decimal point are allowed.
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) return oldValue;

    final dot = raw.indexOf('.');
    var intPart = dot >= 0 ? raw.substring(0, dot) : raw;
    var decPart = dot >= 0 ? raw.substring(dot + 1) : null;

    if (intPart.length > maxIntDigits) {
      intPart = intPart.substring(0, maxIntDigits);
    }
    if (decPart != null && decPart.length > 2) {
      decPart = decPart.substring(0, 2); // currencies use at most 2 decimals
    }

    final grouped =
        intPart.isEmpty ? '' : _group.format(int.parse(intPart));
    final out = dot >= 0
        ? '${grouped.isEmpty ? '0' : grouped}.$decPart'
        : grouped;

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// Formats a stored amount into a grouped string for the input field.
String groupedAmount(double v) {
  if (!v.isFinite) return '';
  if (v == v.roundToDouble()) {
    return NumberFormat.decimalPattern('en').format(v.toInt());
  }
  final f = NumberFormat.decimalPattern('en')..maximumFractionDigits = 2;
  return f.format(v);
}
