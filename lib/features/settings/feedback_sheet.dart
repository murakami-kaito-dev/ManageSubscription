import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/text_input.dart';
import '../../core/widgets/soft_button.dart';

/// In-app feedback endpoint. Create a free form (e.g. Formspree) and paste its
/// URL here to submit feedback WITHOUT leaving the app. While it stays as the
/// placeholder, the sheet falls back to the mail composer / share sheet.
const String _feedbackEndpoint = 'https://formspree.io/f/your-form-id';

/// Contact address shown to the user and used for the mailto fallback when
/// [_feedbackEndpoint] isn't configured.
const String _supportEmail = 'solo.developer@gmail.com';

bool get _endpointConfigured =>
    _feedbackEndpoint.isNotEmpty &&
    !_feedbackEndpoint.contains('your-form-id');

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

    const subject = 'サブスク家計簿 ご意見・ご要望';

    // Preferred: submit in-app (no leaving the app) to the form endpoint.
    if (_endpointConfigured) {
      final ok = await _postToEndpoint(subject, text);
      if (!mounted) return;
      setState(() => _sending = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'ご意見ありがとうございます！送信しました。'
              : '送信に失敗しました。時間をおいて再度お試しください。')));
      return;
    }

    // Fallback (no endpoint configured): mail composer, then share.
    var launched = false;
    final mailto = Uri.parse(
        'mailto:$_supportEmail?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(mailto)) {
        launched =
            await launchUrl(mailto, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
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

  Future<bool> _postToEndpoint(String subject, String message) async {
    try {
      final res = await http
          .post(
            Uri.parse(_feedbackEndpoint),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'subject': subject, 'message': message}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
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
          Text('ご意見・ご要望', style: AppType.display(20)),
          const Gap(AppSpacing.sm),
          Text('要望・不具合をお気軽にご連絡ください。改善の参考にいたします。',
              style: AppType.body(13,
                  color: AppColors.textSecondary, height: 1.5)),
          const Gap(AppSpacing.lg),
          Text('連絡先メールアドレス',
              style: AppType.body(12, color: AppColors.textSecondary)),
          const Gap(AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded,
                  size: 16, color: AppColors.textMuted),
              const Gap(6),
              Text(_supportEmail,
                  style: AppType.body(13.5, weight: FontWeight.w600)),
            ],
          ),
          const Gap(AppSpacing.lg),
          Text('お問い合わせ内容',
              style: AppType.body(12, color: AppColors.textSecondary)),
          const Gap(AppSpacing.xs),
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
              contextMenuBuilder: noCameraScanContextMenu,
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
