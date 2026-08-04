#!/usr/bin/env bash
#
# upload_to_appstore.sh — build the iOS .ipa and upload it to App Store Connect
# (TestFlight) using an App Store Connect API key. Fully non-interactive.
#
# Credentials (never committed — see .gitignore):
#   ios/AuthKey_<KEYID>.p8                  the API private key
#   ios/AppStoreConnectKeyIdIssuerId.json   { "keyID": "...", "issuerID": "..." }
#
# Usage:
#   ios/scripts/upload_to_appstore.sh                 # build + validate + upload
#   ios/scripts/upload_to_appstore.sh --no-build      # reuse the last-built .ipa
#   ios/scripts/upload_to_appstore.sh --validate-only # build + validate, no upload
#   ios/scripts/upload_to_appstore.sh --ipa path.ipa  # upload a specific .ipa
#
# Requirements: Xcode command line tools (xcrun altool), Flutter, and a valid
# distribution signing setup for the app's real Bundle ID (see
# ios/scripts/APPSTORE_SETUP.md). This script does NOT create the Bundle ID or
# the App Store Connect app record — those are one-time steps in that doc.
set -euo pipefail

# ── Resolve project locations ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$IOS_DIR/.." && pwd)"

CRED_JSON="${ASC_CRED_JSON:-$IOS_DIR/AppStoreConnectKeyIdIssuerId.json}"
IPA_DIR="$ROOT_DIR/build/ios/ipa"

# ── Parse flags ──────────────────────────────────────────────────────────────
DO_BUILD=1
DO_UPLOAD=1
IPA_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build)      DO_BUILD=0 ;;
    --validate-only) DO_UPLOAD=0 ;;
    --ipa)           IPA_OVERRIDE="${2:-}"; DO_BUILD=0; shift ;;
    -h|--help)       grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

log()  { printf '\033[1;34m▶ %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m✖ %s\033[0m\n' "$*" >&2; exit 1; }

# ── Preconditions ────────────────────────────────────────────────────────────
command -v xcrun  >/dev/null || fail "xcrun not found (install Xcode command line tools)."
command -v flutter >/dev/null || fail "flutter not found in PATH."
[[ -f "$CRED_JSON" ]] || fail "Credential JSON not found: $CRED_JSON"

# ── Read API key id + issuer id (values are never echoed) ────────────────────
KEY_ID="$(plutil -extract keyID    raw -o - "$CRED_JSON" 2>/dev/null || true)"
ISSUER_ID="$(plutil -extract issuerID raw -o - "$CRED_JSON" 2>/dev/null || true)"
[[ -n "$KEY_ID"    ]] || fail "\"keyID\" missing from $CRED_JSON"
[[ -n "$ISSUER_ID" ]] || fail "\"issuerID\" missing from $CRED_JSON"

# ── Locate the .p8 private key ───────────────────────────────────────────────
P8="$IOS_DIR/AuthKey_${KEY_ID}.p8"
if [[ ! -f "$P8" ]]; then
  P8="$(ls "$IOS_DIR"/AuthKey_*.p8 2>/dev/null | head -1 || true)"
fi
[[ -n "$P8" && -f "$P8" ]] || fail "API private key AuthKey_${KEY_ID}.p8 not found in $IOS_DIR"

# altool looks for AuthKey_<KEYID>.p8 in ~/.appstoreconnect/private_keys.
# Copy it there (outside the repo) with tight permissions.
PK_DIR="$HOME/.appstoreconnect/private_keys"
mkdir -p "$PK_DIR"; chmod 700 "$PK_DIR"
cp "$P8" "$PK_DIR/AuthKey_${KEY_ID}.p8"
chmod 600 "$PK_DIR/AuthKey_${KEY_ID}.p8"
log "API key installed for altool (Key ID ends …${KEY_ID: -4})."

# ── Build the .ipa ───────────────────────────────────────────────────────────
if [[ "$DO_BUILD" -eq 1 ]]; then
  log "flutter build ipa --release"
  ( cd "$ROOT_DIR" && flutter build ipa --release )
fi

# ── Resolve the .ipa to upload ───────────────────────────────────────────────
if [[ -n "$IPA_OVERRIDE" ]]; then
  IPA="$IPA_OVERRIDE"
else
  IPA="$(ls -t "$IPA_DIR"/*.ipa 2>/dev/null | head -1 || true)"
fi
[[ -n "$IPA" && -f "$IPA" ]] || fail "No .ipa found. Run without --no-build, or pass --ipa <path>. (looked in $IPA_DIR)"
log "Using IPA: $IPA"

APIARGS=(--apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID" --type ios)

# ── Validate, then upload ────────────────────────────────────────────────────
log "Validating with App Store Connect…"
xcrun altool --validate-app --file "$IPA" "${APIARGS[@]}" \
  || fail "Validation failed — fix the reported issues before uploading."

if [[ "$DO_UPLOAD" -eq 0 ]]; then
  log "Validation passed. Skipping upload (--validate-only)."
  exit 0
fi

log "Uploading to App Store Connect (TestFlight)…"
xcrun altool --upload-app --file "$IPA" "${APIARGS[@]}"

log "Done. The build will appear in TestFlight after Apple finishes processing (usually 5–30 min)."
