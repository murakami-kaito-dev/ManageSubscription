#!/usr/bin/env bash
#
# fresh_install.sh — uninstall the app from the connected device(s) and reinstall
# a clean, freshly-initialized build (empty database → the default seed only).
#
# Use this after a data-corruption bug, or any time you want a clean slate. It
# removes the existing install (which is what wipes the local DB / images) and
# then runs the app again.
#
# Usage:
#   scripts/fresh_install.sh                 # release build, dev unlock on
#   scripts/fresh_install.sh -d <deviceId>   # extra args pass through to flutter run
set -euo pipefail

IOS_BUNDLE_ID="com.submana.app"
ANDROID_APP_ID="com.example.manage_subscription"

log() { printf '\033[1;34m▶ %s\033[0m\n' "$*"; }

# ── Uninstall from wherever we can (all best-effort; ignore "not installed") ──
if command -v adb >/dev/null 2>&1; then
  for serial in $(adb devices | awk 'NR>1 && $2=="device"{print $1}'); do
    log "Android: uninstalling $ANDROID_APP_ID from $serial"
    adb -s "$serial" uninstall "$ANDROID_APP_ID" >/dev/null 2>&1 || true
  done
fi

if command -v xcrun >/dev/null 2>&1; then
  log "iOS Simulator: uninstalling $IOS_BUNDLE_ID (if booted)"
  xcrun simctl uninstall booted "$IOS_BUNDLE_ID" >/dev/null 2>&1 || true
fi

if command -v ios-deploy >/dev/null 2>&1; then
  log "iOS device: uninstalling $IOS_BUNDLE_ID (if connected)"
  ios-deploy --uninstall_only --bundle_id "$IOS_BUNDLE_ID" >/dev/null 2>&1 || true
fi

# ── Reinstall a clean build ──────────────────────────────────────────────────
log "Reinstalling a fresh build…"
exec flutter run --release --dart-define=DEV_UNLOCK=true "$@"
