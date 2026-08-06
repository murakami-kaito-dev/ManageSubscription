import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';

/// Fixed help page describing the CSV format for import: every column, the
/// values allowed and forbidden, and a shareable sample template. Keeping this
/// in the app prevents users from breaking the format.
class CsvImportHelpScreen extends StatelessWidget {
  const CsvImportHelpScreen({super.key});

  // Header must match what export writes / import expects.
  static const _header = [
    'サービス名', '金額', '通貨', '周期', '初回支払日', '次回支払日',
    'カテゴリー', '支払い方法', '月額換算', '利用回数/月', '1回あたり単価', '状態', 'メモ',
  ];

  static const _sampleRows = [
    ['Netflix', '1490', 'JPY', '月', '2026/08/15', '', 'エンタメ', 'クレジットカード',
        '', '8', '', '利用中', '見放題プラン'],
    ['Notion', '8', 'USD', '年', '2026/04/01', '', '仕事', '', '', '', '', '利用中', ''],
    ['スポーツジム', '9800', 'JPY', '2週', '2026/08/10', '', '健康', '現金', '', '',
        '', '停止中', '隔週利用'],
  ];

  static const _columns = <({String name, String required, String allow, String forbid})>[
    // 「禁止・注意」＝その値だと**その行がスキップ（取り込まれない）**になるもの。
    // 行がスキップされないものは「なし」と明記する。
    (name: 'サービス名', required: '必須', allow: '任意の文字列（例：Netflix）', forbid: '空欄'),
    (name: '金額', required: '必須', allow: '0〜100,000,000（1億）の数値。カンマ・¥可', forbid: '空欄 / 数値でない / マイナス / 1億超'),
    (name: '通貨', required: '必須', allow: 'JPY / USD / EUR / GBP（大文字小文字は不問）', forbid: '空欄 / 左記以外のコード'),
    (name: '周期', required: '必須', allow: '月 / 年 / 週、またはカスタム（例：3ヶ月・2週・5日）', forbid: '空欄 / 左記以外の語（例：毎月・NEN）'),
    (name: '初回支払日', required: '必須', allow: 'yyyy/MM/dd（- や . 区切りも可）。2000〜2100年', forbid: '空欄 / 存在しない日付 / 2000〜2100年の範囲外 / 形式不正'),
    (name: 'カテゴリー', required: '任意', allow: 'アプリに登録済みのカテゴリー名', forbid: 'なし（不一致の名前は「未設定」になるだけで、行はスキップされません）'),
    (name: '支払い方法', required: '任意', allow: 'アプリに登録済みの支払い方法名', forbid: 'なし（不一致の名前は「未設定」になるだけで、行はスキップされません）'),
    (name: '利用回数/月', required: '任意', allow: '数値（コスパ計算用）', forbid: 'なし（空欄・不正値は0として扱い、行はスキップされません）'),
    (name: '状態', required: '任意', allow: '「停止中」＝停止／それ以外＝利用中', forbid: 'なし（どんな値でも行はスキップされません）'),
    (name: 'メモ', required: '任意', allow: '任意の文字列', forbid: 'なし'),
    (name: '次回支払日 / 月額換算 / 1回あたり単価', required: '無視', allow: 'エクスポート専用（取り込み時は読み込みません）', forbid: 'なし（値が入っていても無視され、行はスキップされません）'),
  ];

  String _sampleCsvString() {
    final rows = <List<Object?>>[_header, ..._sampleRows];
    // BOM so Excel opens the Japanese text as UTF-8.
    return '﻿${const ListToCsvConverter().convert(rows)}';
  }

  Future<void> _shareSample() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/subscriptions_template.csv');
    await file.writeAsString(_sampleCsvString());
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')],
        subject: 'サブスク家計簿 CSVテンプレート');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: 'CSVの書式',
              leading: SoftIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 40),
                children: [
                  SoftCard(
                    child: Text(
                      'アプリでエクスポートしたCSVと同じ見出し行が必要です。文字コードは'
                      'UTF-8。下の「テンプレートを共有」で正しい形式のひな型を入手できます。\n\n'
                      '「禁止・注意」は、その値だと**その行が取り込まれずスキップされる**もの'
                      'です（該当行以外は正常に取り込まれます）。スキップされない列は「なし」と'
                      '記載しています。',
                      style: AppType.body(13,
                          color: AppColors.textSecondary, height: 1.6),
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                  Text('各カラムの説明',
                      style: AppType.body(13,
                          weight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const Gap(AppSpacing.sm),
                  for (final c in _columns) ...[
                    _ColumnCard(column: c),
                    const Gap(AppSpacing.sm),
                  ],
                  const Gap(AppSpacing.md),
                  SoftButton(
                    label: 'テンプレート（サンプル）を共有',
                    icon: Icons.description_rounded,
                    onPressed: _shareSample,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnCard extends StatelessWidget {
  const _ColumnCard({required this.column});
  final ({String name, String required, String allow, String forbid}) column;

  @override
  Widget build(BuildContext context) {
    final isOptional = column.required != '必須';
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(column.name, style: AppType.display(15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOptional
                      ? AppColors.surfaceSunken
                      : AppAccent.of(context).soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(column.required,
                    style: AppType.body(11,
                        weight: FontWeight.w700,
                        color: isOptional
                            ? AppColors.textSecondary
                            : AppAccent.of(context).deep)),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          _kv('許可', column.allow, AppColors.textPrimary),
          const Gap(4),
          // Every column shows 禁止・注意; "なし" rows are neutral, real
          // skip-causing prohibitions are shown in the danger color.
          _kv(
            '禁止・注意',
            column.forbid,
            column.forbid.startsWith('なし')
                ? AppColors.textSecondary
                : AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, Color valueColor) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(k,
                style: AppType.body(12,
                    weight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(v,
                style: AppType.body(12.5, color: valueColor, height: 1.5)),
          ),
        ],
      );
}
