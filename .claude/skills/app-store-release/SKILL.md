---
name: app-store-release
description: Build and ship this Flutter app (サブスク家計簿 / manage_subscription) to App Store Connect / TestFlight. Use whenever the user wants to submit, release, ship, or upload a new build. Claude can complete the upload with ONE command via ios/scripts/upload_to_appstore.sh (App Store Connect API key), after running the pre-flight checks. Covers the commonly-forgotten items (build-number bump, export compliance, icon alpha, privacy manifest) and the one-time signing setup only the human can do.
---

# App Store Release — サブスク家計簿 (manage_subscription)

Uploading is **automated**: `ios/scripts/upload_to_appstore.sh` builds the
`.ipa`, then validates and uploads it to App Store Connect using the App Store
Connect **API key** (no Apple-ID password, no interactive Xcode Organizer).
Claude can run it. Run the pre-flight checks first, fix what's fixable in the
repo, then execute the script.

## Fixed project facts

| Item | Value |
|---|---|
| App (store) name | サブスク家計簿 |
| Bundle ID | `com.submana.app` (tests `com.submana.app.RunnerTests`) |
| Team ID | `XX24WCN326` |
| API key | `ios/AuthKey_B5TW9QHTS7.p8` + `ios/AppStoreConnectKeyIdIssuerId.json` (`keyID` + `issuerID`) — **git-ignored, never commit** |
| Upload script | `ios/scripts/upload_to_appstore.sh` |
| One-time setup | `ios/scripts/APPSTORE_SETUP.md` |

## One-command upload (what Claude runs to ship)

```bash
ios/scripts/upload_to_appstore.sh --validate-only   # dry run: build + validate
ios/scripts/upload_to_appstore.sh                   # build + validate + UPLOAD
```
The script reads the Key/Issuer ID from the JSON (never printed), installs the
`.p8` where `altool` expects it, runs `flutter build ipa --release`, then
`xcrun altool --validate-app` and `--upload-app`. Uploading is outward-facing —
**confirm with the user before running the real (non-`--validate-only`) upload.**

## Pre-flight checks (automate these; run before uploading)

1. **Bundle ID is real.** `grep PRODUCT_BUNDLE_IDENTIFIER ios/Runner.xcodeproj/project.pbxproj`
   → must be `com.submana.app` (+ `.RunnerTests`), never `com.example`. It is
   PERMANENT after the first upload.

2. **Build number bumped.** Every upload needs a higher build number.
   `pubspec.yaml` `version: X.Y.Z+N` — increment `N` (currently `1.0.0+1`). Also
   update the hardcoded footer string `'v1.0.0'` in
   `lib/features/settings/settings_screen.dart` to match `X.Y.Z` (synced by hand).

3. **Export compliance present.** `ios/Runner/Info.plist` contains
   `ITSAppUsesNonExemptEncryption` = `<false/>` (app uses only standard TLS).
   Keep it so the encryption question is never asked at upload.

4. **App icon has no alpha** (App Store rejects alpha on the 1024 icon):
   `sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
   → must be `no`. Regenerate with `dart run flutter_launcher_icons` if needed
   (dep `flutter_launcher_icons` is in `pubspec.yaml`).

5. **Code is green.** `flutter analyze` (0 issues) and `flutter test` (all pass).

6. **Project still parses after any pbxproj edit:**
   `xcodebuild -list -project ios/Runner.xcodeproj`.

7. **Premium gating matches intent.** Monetization is not finalized. Confirm the
   free/premium split (`premiumProvider`, `PremiumLimits`, `PremiumScreen`) is in
   the state you want to ship; the hidden debug toggle (long-press the version in
   Settings) must not leave premium force-on unintentionally.

## One-time human steps (Claude cannot do — Apple ID / 2FA / live account)

Only needed once, then every future upload is one command. Full detail in
`ios/scripts/APPSTORE_SETUP.md`:

1. **Xcode signing**: Xcode ▸ Settings ▸ Accounts ▸ add Apple ID; then Runner ▸
   Signing & Capabilities ▸ Automatically manage signing ▸ Team `XX24WCN326`.
2. **App Store Connect app record**: Apps ▸ + ▸ New App — Bundle ID
   `com.submana.app`, name サブスク家計簿, language Japanese, SKU `subsc-001`.
   (Claude can create this via the App Store Connect API on request — it's a live
   account change, so confirm first.)

## Before App Store *review* (not required just to upload to TestFlight)

- **Privacy manifest** `ios/Runner/PrivacyInfo.xcprivacy` is currently **absent**;
  Apple requires it for review (AdMob / RevenueCat / required-reason APIs). Create
  it, declaring data collection + required-reason API reasons, before submitting.
- App Store Connect listing: Pricing/Availability, **App Privacy** answers,
  screenshots (6.7"/6.5" iPhone), description, keywords, support URL, **privacy
  policy URL**, age rating, then select the build ▸ Submit for Review.

## Notes

- Android `applicationId` is separate (`com.example.*`); only fix for Google Play.
- Credentials live in `ios/` and are git-ignored via both the repo-root and
  `ios/.gitignore` (patterns `*.p8`, `AppStoreConnect*.json`). Never commit them.
