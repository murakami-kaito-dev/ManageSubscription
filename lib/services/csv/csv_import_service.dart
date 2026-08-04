import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/billing.dart';
import '../../core/utils/currency.dart';
import '../../data/models/notify_rule.dart';
import '../../data/models/subscription.dart';

/// One row that could not be imported, with a human-readable reason.
class CsvRowError {
  const CsvRowError(this.line, this.message);

  /// 1-based row number as it appears in the file (header = line 1).
  final int line;
  final String message;
}

/// Outcome of parsing a CSV. Either [fatal] is set (the whole file was rejected
/// without touching any data), or [valid]/[errors] describe row-by-row results.
class CsvImportResult {
  const CsvImportResult({
    this.valid = const [],
    this.errors = const [],
    this.fatal,
  });

  /// Ready-to-save subscriptions (fresh IDs — importing never overwrites).
  final List<Subscription> valid;
  final List<CsvRowError> errors;

  /// Non-null when the file's shape is unusable (bad header, empty, etc.).
  final String? fatal;

  bool get hasFatal => fatal != null;
  int get validCount => valid.length;
  int get errorCount => errors.length;
}

/// Reads a CSV and turns it into subscriptions **defensively**: the file is
/// parsed and validated into an in-memory preview first; nothing is written to
/// the database until the caller explicitly saves the [CsvImportResult.valid]
/// list. Malformed rows are skipped with a reason — a broken file can never
/// corrupt or delete existing data.
class CsvImportService {
  const CsvImportService();

  static const _uuid = Uuid();

  // Columns we read. Derived columns in the export (次回支払日 / 月額換算 /
  // 1回あたり単価) are ignored on import.
  static const _colName = 'サービス名';
  static const _colAmount = '金額';
  static const _colCurrency = '通貨';
  static const _colCycle = '周期';
  static const _colFirst = '初回支払日';
  static const _colCategory = 'カテゴリー';
  static const _colMethod = '支払い方法';
  static const _colUsage = '利用回数/月';
  static const _colState = '状態';
  static const _colMemo = 'メモ';

  static const _required = [
    _colName,
    _colAmount,
    _colCurrency,
    _colCycle,
    _colFirst,
  ];

  /// Opens the file picker and returns the CSV text, or null if cancelled.
  Future<String?> pickCsvText() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.first;
    if (f.bytes != null) {
      // Decode leniently so an odd byte never throws; malformed rows are caught
      // later by validation.
      return utf8.decode(f.bytes!, allowMalformed: true);
    }
    if (f.path != null) {
      return File(f.path!).readAsString();
    }
    return null;
  }

  /// Parses [content] into a preview. [categoryNameToId] / [methodNameToId] map
  /// the human names in the CSV back to existing entities (unmatched → unset).
  CsvImportResult parse(
    String content, {
    Map<String, String> categoryNameToId = const {},
    Map<String, String> methodNameToId = const {},
    int startSortOrder = 0,
  }) {
    // Strip a UTF-8 BOM if present (our export writes one for Excel).
    final text = content.replaceFirst('﻿', '').trim();
    if (text.isEmpty) {
      return const CsvImportResult(fatal: 'ファイルが空です。');
    }

    List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
    } catch (e) {
      return CsvImportResult(fatal: 'CSVとして読み取れませんでした：$e');
    }
    if (rows.isEmpty) {
      return const CsvImportResult(fatal: '行がありません。');
    }

    // Map header → column index.
    final header = rows.first.map((c) => c.toString().trim()).toList();
    final index = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      index.putIfAbsent(header[i], () => i);
    }
    final missing = _required.where((c) => !index.containsKey(c)).toList();
    if (missing.isNotEmpty) {
      return CsvImportResult(
          fatal: '必要な列が見つかりません：${missing.join('、')}\n'
              'アプリでエクスポートしたCSVと同じ見出し行が必要です。');
    }

    final valid = <Subscription>[];
    final errors = <CsvRowError>[];

    String cell(List<dynamic> row, String col) {
      final i = index[col];
      if (i == null || i >= row.length) return '';
      return row[i].toString().trim();
    }

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final fileLine = r + 1; // 1-based, header is line 1
      // A fully blank line is silently skipped, not treated as an error.
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      try {
        final sub = _parseRow(
          row: row,
          cell: (col) => cell(row, col),
          categoryNameToId: categoryNameToId,
          methodNameToId: methodNameToId,
          sortOrder: startSortOrder + valid.length,
        );
        valid.add(sub);
      } on _RowError catch (e) {
        errors.add(CsvRowError(fileLine, e.message));
      } catch (e) {
        // Absolutely never let one row take down the import.
        errors.add(CsvRowError(fileLine, '読み取れませんでした：$e'));
      }
    }

    return CsvImportResult(valid: valid, errors: errors);
  }

  Subscription _parseRow({
    required List<dynamic> row,
    required String Function(String col) cell,
    required Map<String, String> categoryNameToId,
    required Map<String, String> methodNameToId,
    required int sortOrder,
  }) {
    final name = cell(_colName);
    if (name.isEmpty) throw const _RowError('サービス名が空です。');

    final amount = _parseAmount(cell(_colAmount));
    final currencyCode = _parseCurrency(cell(_colCurrency));
    final (cycle, count, unit) = _parseCycle(cell(_colCycle));
    final first = _parseDate(cell(_colFirst));

    final usage = _parseUsage(cell(_colUsage));
    final paused = cell(_colState) == '停止中';
    final memo = cell(_colMemo);
    final catId = categoryNameToId[cell(_colCategory)];
    final pmId = methodNameToId[cell(_colMethod)];

    return Subscription(
      id: _uuid.v4(),
      name: name,
      amount: amount,
      currencyCode: currencyCode,
      cycle: cycle,
      intervalCount: count,
      intervalUnit: unit,
      firstPaymentDate: first,
      colorValue: AppColors.chartPalette[sortOrder % AppColors.chartPalette.length].value,
      categoryId: catId,
      paymentMethodId: pmId,
      memo: memo.isEmpty ? null : memo,
      usageCount: usage,
      usageUnit: '回',
      isPaused: paused,
      notifyRules: const [NotifyRule(daysBefore: 1)],
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  double _parseAmount(String raw) {
    if (raw.isEmpty) throw const _RowError('金額が空です。');
    // Tolerate currency symbols / thousands separators a user might type.
    final cleaned = raw.replaceAll(RegExp(r'[^\d.\-]'), '');
    final v = double.tryParse(cleaned);
    if (v == null) throw _RowError('金額「$raw」を数値として読み取れません。');
    if (v < 0) throw _RowError('金額「$raw」が負の値です。');
    return v;
  }

  String _parseCurrency(String raw) {
    final code = raw.toUpperCase();
    final ok = AppCurrency.values.any((c) => c.code == code);
    if (!ok) {
      throw _RowError('通貨「$raw」は未対応です（JPY / USD / EUR / GBP）。');
    }
    return code;
  }

  (BillingCycle, int, IntervalUnit) _parseCycle(String raw) {
    switch (raw) {
      case '月':
        return (BillingCycle.monthly, 1, IntervalUnit.month);
      case '年':
        return (BillingCycle.yearly, 12, IntervalUnit.month);
      case '週':
        return (BillingCycle.weekly, 1, IntervalUnit.week);
    }
    // Custom: "<n>日" / "<n>週" / "<n>ヶ月".
    final m = RegExp(r'^(\d+)\s*(日|週|ヶ月)$').firstMatch(raw);
    if (m != null) {
      final n = int.parse(m.group(1)!);
      if (n >= 1) {
        final unit = switch (m.group(2)) {
          '日' => IntervalUnit.day,
          '週' => IntervalUnit.week,
          _ => IntervalUnit.month,
        };
        return (BillingCycle.custom, n, unit);
      }
    }
    throw _RowError('周期「$raw」を読み取れません（月 / 年 / 週 / 3ヶ月 / 2週 / 5日 など）。');
  }

  DateTime _parseDate(String raw) {
    if (raw.isEmpty) throw const _RowError('初回支払日が空です。');
    final norm = raw.replaceAll('-', '/').replaceAll('.', '/');
    final m = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$').firstMatch(norm);
    if (m == null) {
      throw _RowError('初回支払日「$raw」の形式が不正です（例：2026/08/05）。');
    }
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) {
      throw _RowError('初回支払日「$raw」に無効な月日が含まれます。');
    }
    final dt = DateTime(y, mo, d);
    // Reject rollovers like 2026/02/31 → 2026/03/03.
    if (dt.month != mo || dt.day != d) {
      throw _RowError('初回支払日「$raw」は存在しない日付です。');
    }
    return dt;
  }

  /// Usage is optional; blank/garbage defaults to 0 rather than failing the row.
  double _parseUsage(String raw) {
    if (raw.isEmpty) return 0;
    return double.tryParse(raw.replaceAll(RegExp(r'[^\d.\-]'), '')) ?? 0;
  }
}

class _RowError implements Exception {
  const _RowError(this.message);
  final String message;
}
