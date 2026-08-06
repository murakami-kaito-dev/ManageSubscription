import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/services/csv/csv_import_service.dart';

/// Parses the committed sample CSVs in test/fixtures/csv and asserts the
/// outcome. These same files can be imported in the app for manual testing.
const _service = CsvImportService();

CsvImportResult _parseFixture(String name) {
  final text = File('test/fixtures/csv/$name').readAsStringSync();
  return _service.parse(text);
}

void main() {
  group('CSV fixtures — 正常系', () {
    test('01_valid_all_columns: すべて取り込める', () {
      final r = _parseFixture('01_valid_all_columns.csv');
      expect(r.hasFatal, isFalse);
      expect(r.validCount, 5);
      expect(r.errorCount, 0);
    });
  });

  group('CSV fixtures — 異常系', () {
    test('02_mixed: 正常3・エラー2（アイテム別にグループ）', () {
      final r = _parseFixture('02_mixed_valid_and_errors.csv');
      expect(r.validCount, 3);
      expect(r.errorCount, 2);
      expect(r.errors.map((e) => e.name), containsAll(['BadCurrency', 'BadCycle']));
    });

    test('03_all_invalid: 取り込み0・エラー5', () {
      final r = _parseFixture('03_all_invalid.csv');
      expect(r.validCount, 0);
      expect(r.errorCount, 5);
    });

    test('04_missing_required_column: ファイル全体を拒否(fatal)', () {
      final r = _parseFixture('04_missing_required_column.csv');
      expect(r.hasFatal, isTrue);
      expect(r.fatal, contains('金額'));
      expect(r.valid, isEmpty);
    });

    test('05_empty: 空ファイルは fatal（クラッシュしない）', () {
      final r = _parseFixture('05_empty.csv');
      expect(r.hasFatal, isTrue);
    });

    test('06_edge_cases: 境界値と複合エラー', () {
      final r = _parseFixture('06_edge_cases.csv');
      // 1億ちょうど / 2000年 / 2100年 の3件のみ取り込み
      expect(r.validCount, 3);
      expect(r.valid.map((s) => s.name),
          containsAll(['AtCap', 'Year2000', 'Year2100']));
      // 1億超 / 範囲外年 / 巨大値 / 複合 の4件はスキップ
      expect(r.errorCount, 4);
      // 取り込んだ金額はすべて有限かつ上限以内
      for (final s in r.valid) {
        expect(s.amount.isFinite, isTrue);
        expect(s.amount <= 100000000, isTrue);
      }
      // MultiError は1枠に複数メッセージ
      final multi = r.errors.firstWhere((e) => e.name == 'MultiError');
      expect(multi.messages.length, greaterThanOrEqualTo(3));
      expect(multi.heading, contains('MultiError（'));
    });
  });
}
