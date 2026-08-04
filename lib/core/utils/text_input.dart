import 'package:flutter/material.dart';

/// A [contextMenuBuilder] that shows the normal selection toolbar but removes
/// the "Scan Text from Camera" (Live Text) button.
///
/// iOS adds a `captureTextFromCamera` item to every editable field by default;
/// it launches the camera and is not wanted here. We keep every other button
/// (cut / copy / paste / select-all …) and just drop the Live Text one.
Widget noCameraScanContextMenu(
    BuildContext context, EditableTextState state) {
  final items = state.contextMenuButtonItems
      .where((b) => b.type != ContextMenuButtonType.liveTextInput)
      .toList();
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: state.contextMenuAnchors,
    buttonItems: items,
  );
}
