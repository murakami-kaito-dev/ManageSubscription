import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared delete-confirmation dialog. Layout is consistent everywhere:
/// [lead] (what happens) at the top, then the irreversible warning in red,
/// then an optional grey [tailNote] at the bottom. Returns true if confirmed.
Future<bool> showDeleteDialog(
  BuildContext context, {
  String title = '削除しますか？',
  required Widget lead,
  String? tailNote,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: AppType.display(19)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: AppType.body(14, height: 1.5),
            child: lead,
          ),
          const SizedBox(height: 8),
          Text('この操作は取り消せません。',
              style: AppType.body(14,
                  weight: FontWeight.w700, color: AppColors.danger)),
          if (tailNote != null) ...[
            const SizedBox(height: 14),
            Text(tailNote,
                style: AppType.body(12.5,
                    color: AppColors.textSecondary, height: 1.5)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除',
                style: TextStyle(color: AppColors.danger))),
      ],
    ),
  );
  return ok ?? false;
}
