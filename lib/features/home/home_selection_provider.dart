import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home-list multi-select state (for bulk delete). Entered from the home "…"
/// menu, exited on cancel or after deleting.
class HomeSelection {
  const HomeSelection({this.active = false, this.ids = const {}});
  final bool active;
  final Set<String> ids;

  int get count => ids.length;

  HomeSelection copyWith({bool? active, Set<String>? ids}) =>
      HomeSelection(active: active ?? this.active, ids: ids ?? this.ids);
}

class HomeSelectionNotifier extends Notifier<HomeSelection> {
  @override
  HomeSelection build() => const HomeSelection();

  void enter() => state = const HomeSelection(active: true, ids: {});
  void exit() => state = const HomeSelection();

  void toggle(String id) {
    final next = {...state.ids};
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(ids: next);
  }

  void selectAll(Iterable<String> ids) => state = state.copyWith(ids: {...ids});
  void clear() => state = state.copyWith(ids: {});
}

final homeSelectionProvider =
    NotifierProvider<HomeSelectionNotifier, HomeSelection>(
        HomeSelectionNotifier.new);
