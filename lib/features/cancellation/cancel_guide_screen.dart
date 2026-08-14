import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/text_input.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../settings/settings_screen.dart';
import 'cancel_guide_data.dart';

/// 「解約方法」タブ。登録先・サービスごとに**公式の解約ページへ遷移するだけ**の
/// リンク集（[kCancelGuideEntries]）。手順は載せない／このアプリで解約手続きは
/// しない、という前提は文言にもそのまま出す。
class CancelGuideScreen extends StatefulWidget {
  const CancelGuideScreen({super.key});

  @override
  State<CancelGuideScreen> createState() => _CancelGuideScreenState();
}

class _CancelGuideScreenState extends State<CancelGuideScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final hits = searchCancelGuide(_query);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: '解約方法',
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const SettingsScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 40),
                children: [
                  const _IntroCard(),
                  const Gap(AppSpacing.lg),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  if (searching)
                    ..._buildSearchResults(hits)
                  else
                    ..._buildSections(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections() => [
        for (final section in cancelGuideSections()) ...[
          SectionHeader(section.category.label),
          _EntryCard(entries: section.entries),
        ],
      ];

  List<Widget> _buildSearchResults(List<CancelGuideEntry> hits) => [
        SectionHeader('検索結果（${hits.length}件）'),
        if (hits.isEmpty)
          SoftCard(
            child: Text(
              'そのサービスはまだ収録していません。\n'
              'アプリ内から登録したものなら、上の「App Store で登録したサブスク」から解約できます。',
              style: AppType.body(13.5,
                  color: AppColors.textSecondary, height: 1.6),
            ),
          )
        else
          _EntryCard(entries: hits),
      ];
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.open_in_new_rounded,
                  size: 20, color: AppAccent.of(context).deep),
              const Gap(AppSpacing.sm),
              Text('公式の解約ページを開きます', style: AppType.display(16)),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            'このアプリで解約の手続きはできません。サービスを選ぶと、公式の解約ページをブラウザで開きます。\n'
            'アプリ内から登録したサブスクは、サービスのサイトではなく App Store / Google Play から解約します。',
            style:
                AppType.body(13, color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textMuted),
          const Gap(AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              contextMenuBuilder: noCameraScanContextMenu,
              style: AppType.body(14.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'サービス名で探す',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            Pressable(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// 1枚のカードに行を積む（設定画面と同じ見た目）。
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entries});

  final List<CancelGuideEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const _Div(),
            _EntryRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final CancelGuideEntry entry;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.99,
      onTap: () => showCancelGuideSheet(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Icon(entry.category.icon,
                size: 22, color: AppAccent.of(context).deep),
            const Gap(AppSpacing.md),
            Expanded(child: Text(entry.name, style: AppType.body(15))),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Divider(height: 1, color: AppColors.textMuted.withOpacity(0.15)),
      );
}

/// サービス1件の詳細シート。開くのは公式ページだけ、というのが分かる形にする。
Future<void> showCancelGuideSheet(
    BuildContext context, CancelGuideEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    builder: (_) => _CancelGuideSheet(entry: entry),
  );
}

class _CancelGuideSheet extends StatelessWidget {
  const _CancelGuideSheet({required this.entry});

  final CancelGuideEntry entry;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(entry.url);
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {/* best-effort */}
    if (!context.mounted) return;
    if (launched) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ページを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Gap(AppSpacing.lg),
            Text(entry.name, style: AppType.display(20)),
            const Gap(AppSpacing.lg),
            _Block(
              icon: Icons.alt_route_rounded,
              label: 'どこから解約するか',
              text: entry.route,
            ),
            if (entry.caution != null) ...[
              const Gap(AppSpacing.md),
              _Block(
                icon: Icons.info_outline_rounded,
                label: '解約する前に',
                text: entry.caution!,
              ),
            ],
            const Gap(AppSpacing.xl),
            SoftButton(
              label: '公式の解約ページを開く',
              icon: Icons.open_in_new_rounded,
              onPressed: () => _open(context),
            ),
            const Gap(AppSpacing.sm),
            Text(
              'ブラウザで公式ページを開きます。このアプリからは解約できません。',
              style: AppType.body(11.5, color: AppColors.textMuted),
            ),
            const Gap(AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.icon, required this.label, required this.text});

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textMuted),
            const Gap(6),
            Text(label,
                style: AppType.body(12,
                    weight: FontWeight.w700, color: AppColors.textSecondary)),
          ],
        ),
        const Gap(AppSpacing.xs),
        Text(text,
            style: AppType.body(13.5, height: 1.6)),
      ],
    );
  }
}
