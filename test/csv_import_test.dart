import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/billing.dart';
import 'package:manage_subscription/services/csv/csv_import_service.dart';

const _service = CsvImportService();

const _header =
    'サービス名,金額,通貨,周期,初回支払日,次回支払日,カテゴリー,支払い方法,月額換算,利用回数/月,1回あたり単価,状態,メモ';

String _csv(List<String> dataRows) => [_header, ...dataRows].join('\n');

void main() {
  group('CSV import — defensive parsing', () {
    test('parses valid rows and skips malformed ones without a fatal', () {
      final csv = _csv([
        'Netflix,1490,JPY,月,2026/08/15,,,,1490,8,,利用中,好きな番組',
        'BadAmount,abc,JPY,月,2026/08/01,,,,,,,利用中,',
        'BadDate,500,JPY,月,2026/13/40,,,,,,,利用中,',
        ',500,JPY,月,2026/08/01,,,,,,,利用中,', // empty name
        'BadCurrency,500,XYZ,月,2026/08/01,,,,,,,利用中,',
        'BadCycle,500,JPY,隔月,2026/08/01,,,,,,,利用中,',
      ]);

      final r = _service.parse(csv);

      expect(r.hasFatal, isFalse);
      expect(r.validCount, 1);
      expect(r.errorCount, 5);
      expect(r.valid.single.name, 'Netflix');
      expect(r.valid.single.amount, 1490);
      // Error line numbers are 1-based including the header (Netflix = line 2).
      expect(r.errors.first.line, 3); // BadAmount is line 3
    });

    test('rejects the whole file when a required column is missing', () {
      const badHeader = 'サービス名,通貨,周期,初回支払日'; // no 金額
      final r = _service.parse('$badHeader\nNetflix,JPY,月,2026/08/15');
      expect(r.hasFatal, isTrue);
      expect(r.fatal, contains('金額'));
      expect(r.valid, isEmpty);
    });

    test('empty content is fatal, not a crash', () {
      expect(_service.parse('').hasFatal, isTrue);
      expect(_service.parse('   \n  ').hasFatal, isTrue);
    });

    test('blank lines are skipped silently (no error)', () {
      final csv = _csv([
        'Netflix,1490,JPY,月,2026/08/15,,,,,,,利用中,',
        ',,,,,,,,,,,,', // all-empty row
        '',
      ]);
      final r = _service.parse(csv);
      expect(r.validCount, 1);
      expect(r.errorCount, 0);
    });

    test('parses every cycle form back to the right recurrence', () {
      final csv = _csv([
        'M,100,JPY,月,2026/01/01,,,,,,,利用中,',
        'Y,100,JPY,年,2026/01/01,,,,,,,利用中,',
        'W,100,JPY,週,2026/01/01,,,,,,,利用中,',
        'C1,100,JPY,3ヶ月,2026/01/01,,,,,,,利用中,',
        'C2,100,JPY,2週,2026/01/01,,,,,,,利用中,',
        'C3,100,JPY,5日,2026/01/01,,,,,,,利用中,',
      ]);
      final r = _service.parse(csv);
      expect(r.validCount, 6);
      final byName = {for (final s in r.valid) s.name: s};
      expect(byName['M']!.cycle, BillingCycle.monthly);
      expect(byName['Y']!.cycle, BillingCycle.yearly);
      expect(byName['W']!.cycle, BillingCycle.weekly);
      expect(byName['C1']!.cycle, BillingCycle.custom);
      expect(byName['C1']!.intervalCount, 3);
      expect(byName['C1']!.intervalUnit, IntervalUnit.month);
      expect(byName['C2']!.intervalUnit, IntervalUnit.week);
      expect(byName['C3']!.intervalUnit, IntervalUnit.day);
    });

    test('maps category / payment-method names to existing IDs', () {
      final csv = _csv([
        'Netflix,1490,JPY,月,2026/08/15,,エンタメ,クレカ,,,,利用中,',
        'Unknown,500,JPY,月,2026/08/01,,存在しない,,,,,,利用中,',
      ]);
      final r = _service.parse(
        csv,
        categoryNameToId: {'エンタメ': 'cat_ent'},
        methodNameToId: {'クレカ': 'pm_card'},
      );
      final byName = {for (final s in r.valid) s.name: s};
      expect(byName['Netflix']!.categoryId, 'cat_ent');
      expect(byName['Netflix']!.paymentMethodId, 'pm_card');
      // Unmatched names leave the field unset rather than failing the row.
      expect(byName['Unknown']!.categoryId, isNull);
    });

    test('tolerates currency case + amount symbols/commas', () {
      final csv = _csv([
        'A,"¥1,490",jpy,月,2026-08-15,,,,,,,利用中,', // hyphen date, ¥, comma, lowercase
      ]);
      final r = _service.parse(csv);
      expect(r.validCount, 1);
      expect(r.valid.single.amount, 1490);
      expect(r.valid.single.currencyCode, 'JPY');
      expect(r.valid.single.firstPaymentDate, DateTime(2026, 8, 15));
    });

    test('rejects huge / non-finite amounts (no Infinity ever imported)', () {
      final csv = _csv([
        'Huge,${'9' * 100},JPY,月,2026/08/15,,,,,,,利用中,', // 100 digits → Infinity
        'OverCap,200000000,JPY,月,2026/08/15,,,,,,,利用中,', // 2億 > 1億 cap
        'AtCap,100000000,JPY,月,2026/08/15,,,,,,,利用中,', // exactly 1億 → ok
      ]);
      final r = _service.parse(csv);
      expect(r.validCount, 1);
      expect(r.errorCount, 2);
      expect(r.valid.single.name, 'AtCap');
      expect(r.valid.single.amount, 100000000);
      // Every imported amount is finite and within the cap.
      for (final s in r.valid) {
        expect(s.amount.isFinite, isTrue);
        expect(s.amount <= 100000000, isTrue);
      }
    });

    test('clamps a large custom-cycle count to the form max (no throw)', () {
      final r = _service.parse(_csv([
        'Big,100,JPY,5000日,2026/08/15,,,,,,,利用中,',
      ]));
      expect(r.validCount, 1);
      expect(r.valid.single.intervalCount, 999); // clamped to 1..999
    });

    test('an overflowing custom-cycle count does not throw (clamps safely)', () {
      final r = _service.parse(_csv([
        'Huge,100,JPY,${'9' * 30}日,2026/08/15,,,,,,,利用中,',
      ]));
      // int overflow → 0 → clamped up to the minimum 1; the row still imports.
      expect(r.validCount, 1);
      expect(r.valid.single.intervalCount, 1);
    });

    test('rejects dates outside the supported 2000..2100 range', () {
      final r = _service.parse(_csv([
        'Old,100,JPY,月,1999/12/31,,,,,,,利用中,',
        'Far,100,JPY,月,3000/01/01,,,,,,,利用中,',
        'Ok,100,JPY,月,2026/08/15,,,,,,,利用中,',
      ]));
      expect(r.validCount, 1);
      expect(r.errorCount, 2);
      expect(r.valid.single.name, 'Ok');
    });

    test('groups every problem on a row under the item name（◯行目）', () {
      final r = _service.parse(_csv([
        'Amazon,abc,ZZZ,NEN,2026/13/40,,,,,,,利用中,', // 4 bad fields
      ]));
      expect(r.validCount, 0);
      expect(r.errorCount, 1);
      final e = r.errors.single;
      expect(e.name, 'Amazon');
      expect(e.line, 2);
      expect(e.heading, 'Amazon（2行目）');
      expect(e.messages.length, greaterThanOrEqualTo(3)); // amount+currency+cycle(+date)
    });

    test('a nameless bad row shows just （◯行目）', () {
      final r = _service.parse(_csv([
        ',100,ZZZ,月,2026/08/15,,,,,,,利用中,',
      ]));
      final e = r.errors.single;
      expect(e.name, isNull);
      expect(e.heading, '（2行目）');
      expect(e.messages, isNotEmpty);
    });

    test('assigns fresh unique IDs so import can never overwrite existing data',
        () {
      final csv = _csv([
        'A,100,JPY,月,2026/01/01,,,,,,,利用中,',
        'A,100,JPY,月,2026/01/01,,,,,,,利用中,', // same content
      ]);
      final r = _service.parse(csv);
      expect(r.validCount, 2);
      expect(r.valid[0].id, isNot(r.valid[1].id));
    });
  });
}
