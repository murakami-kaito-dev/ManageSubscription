/// Developer-only switch: unlocks every premium feature for *your* builds
/// without affecting normal builds.
///
/// It is off by default, so a plain `flutter build` / store build behaves like
/// a real free user (premium remains purchasable). Turn it on only for your own
/// device by passing the define:
///
///   flutter run --release --no-tree-shake-icons --dart-define=DEV_UNLOCK=true
///
/// Because it's a compile-time constant, the flag can never be enabled in a
/// build that didn't explicitly pass it.
const bool kDevUnlockAll =
    bool.fromEnvironment('DEV_UNLOCK', defaultValue: false);
