import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Wraps a list row so it can be dismissed with a left swipe to delete.
/// [onDelete] runs the confirmation and returns true when the item was removed;
/// rows that [canDelete] == false are not swipeable.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    super.key,
    required this.id,
    required this.canDelete,
    required this.onDelete,
    required this.child,
  });

  final String id;
  final bool canDelete;
  final Future<bool> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!canDelete) return child;
    return Dismissible(
      key: ValueKey('dismiss_$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(width: 6),
            Text('削除',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      child: child,
    );
  }
}
