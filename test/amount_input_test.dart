import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/amount_input.dart';

TextEditingValue _v(String s) =>
    TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));

String _fmt(String typed, {String old = ''}) =>
    const ThousandsSeparatorInputFormatter()
        .formatEditUpdate(_v(old), _v(typed))
        .text;

void main() {
  group('ThousandsSeparatorInputFormatter', () {
    test('groups integers with commas', () {
      expect(_fmt('1000'), '1,000');
      expect(_fmt('1000000'), '1,000,000');
      expect(_fmt('100000000'), '100,000,000'); // 1億
    });

    test('keeps a decimal part (max 2 digits)', () {
      expect(_fmt('1234.5'), '1,234.5');
      expect(_fmt('1234.567'), '1,234.56');
    });

    test('empty stays empty', () {
      expect(_fmt(''), '');
    });

    test('caps the integer part at 9 digits (can never become non-finite)', () {
      // 12 digits typed → truncated to 9 significant digits, then grouped.
      expect(_fmt('123456789012'), '123,456,789');
    });

    test('rejects non-numeric input (returns the previous value)', () {
      expect(_fmt('12a', old: '12'), '12');
    });
  });

  group('groupedAmount', () {
    test('formats stored amounts with commas', () {
      expect(groupedAmount(1000), '1,000');
      expect(groupedAmount(100000000), '100,000,000');
      expect(groupedAmount(1234.5), '1,234.5');
    });

    test('non-finite stored amounts render as empty (no crash)', () {
      expect(groupedAmount(double.infinity), '');
      expect(groupedAmount(double.nan), '');
    });
  });

  test('kMaxAmount is 1億', () {
    expect(kMaxAmount, 100000000);
  });
}
