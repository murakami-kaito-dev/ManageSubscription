import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/soft_button.dart';

/// Where feedback is sent. Replace with your real support address.
const String _supportEmail = 'support@example.com';

Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    builder: (_) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    const subject = 'サブスク管理 ご意見・ご要望';
    final mailto = Uri.parse(
        'mailto:$_supportEmail?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(text)}');

    var launched = false;
    try {
      if (await canLaunchUrl(mailto)) {
        launched =
            await launchUrl(mailto, mode: LaunchMode.externalApplication);
      }
    } catch (_) {/* fall through to share */}

    // Fallback: no mail app configured → let the user pick any app.
    if (!launched) {
      try {
        await Share.share('$subject\n\n$text', subject: subject);
        launched = true;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _sending = false);
    if (launched) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ありがとうございます！送信画面を開きました。')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('送信アプリを開けませんでした。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          AppSpacing.lg + bottomInset),
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
          Text('アプリのフィードバック', style: AppType.display(20)),
          const Gap(AppSpacing.sm),
          Text('アプリの不満点や、欲しい機能を自由にお書きください。改善の参考にいたします。',
              style: AppType.body(13,
                  color: AppColors.textSecondary, height: 1.5)),
          const Gap(AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 4,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '〇〇の機能が欲しい',
              ),
            ),
          ),
          const Gap(AppSpacing.lg),
          SoftButton(
            label: _sending ? '送信中…' : '送信する',
            icon: _sending ? null : Icons.send_rounded,
            onPressed: (_controller.text.trim().isEmpty || _sending)
                ? null
                : _send,
          ),
          const Gap(AppSpacing.sm),
        ],
      ),
    );
  }
}
