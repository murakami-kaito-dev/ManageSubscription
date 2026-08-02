import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/category.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/subscription.dart';

/// Builds a CSV of all subscriptions and hands it to the OS share sheet.
/// Premium-only; the caller gates access.
class CsvExportService {
  const CsvExportService();

  Future<void> exportSubscriptions(
    List<Subscription> subs,
    Map<String, Category> categories,
    Map<String, PaymentMethod> methods,
  ) async {
    final df = DateFormat('yyyy/MM/dd');
    final rows = <List<Object?>>[
      [
        'サービス名',
        '金額',
        '通貨',
        '周期',
        '初回支払日',
        '次回支払日',
        'カテゴリー',
        '支払い方法',
        '月額換算',
        '利用回数/月',
        '1回あたり単価',
        '状態',
        'メモ',
      ],
    ];

    for (final s in subs) {
      rows.add([
        s.name,
        s.amount,
        s.currencyCode,
        s.periodLabel,
        df.format(s.firstPaymentDate),
        df.format(s.nextPaymentDate),
        categories[s.categoryId]?.name ?? '',
        methods[s.paymentMethodId]?.name ?? '',
        s.monthlyAmount.round(),
        s.usageCount,
        s.costPerUse?.round() ?? '',
        s.isPaused ? '停止中' : '利用中',
        s.memo ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    // Prepend BOM so Excel opens the Japanese text as UTF-8.
    final content = '﻿$csv';

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/subscriptions_$stamp.csv');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'サブスクリプション一覧 ($stamp)',
    );
  }
}
