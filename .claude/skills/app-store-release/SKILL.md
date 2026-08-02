---
name: app-store-release
description: Prepare and validate this Flutter app (ShipIt English) for an App Store Connect submission or update. Use whenever the user wants to submit, release, ship, or upload a new build to the App Store / TestFlight, or asks to run the pre-submission checklist. Covers the commonly-forgotten items (Bundle ID, encryption declaration, privacy manifest, version bump, icon alpha) and prints the human's manual App Store Connect steps.
---

# App Store Release (ShipIt English)

Run the **pre-flight checks** below in order, fixing what can be fixed in the repo and
reporting anything that needs the user (signing, App Store Connect, decisions).
Then print the **human manual steps**. Detailed background lives in
`docs/app_store_free_release_checklist.md` and `docs/build_and_release.md`.

## Pre-flight checks (automate these)

1. **Bundle ID is not a placeholder.**
   `grep PRODUCT_BUNDLE_IDENTIFIER ios/Runner.xcodeproj/project.pbxproj` — must NOT contain
   `com.example`. The permanent ID is `jp.co.shipitenglish.app` (tests: `.RunnerTests`).
   If it still says `com.example`, STOP and ask the user for the real ID (it is permanent).

2. **Version / build number bumped.** For every new upload the build number must increase.
   - `pubspec.yaml` `version: X.Y.Z+N` (N = build number, must be higher than the last upload).
   - Keep `AppConstants.appVersion` (`lib/core/constants/app_constants.dart`) in sync with `X.Y.Z`
     (shown in Settings footer). These are synced by hand.

3. **Export-compliance declaration present** (avoids the encryption question every upload):
   `ios/Runner/Info.plist` must contain `ITSAppUsesNonExemptEncryption` = `<false/>`.
   (True only if the app adds non-exempt cryptography, which it does not.)

4. **Privacy manifest present and wired in.** `ios/Runner/PrivacyInfo.xcprivacy` must exist,
   `plutil -lint` clean, and be a Runner **resource** in `project.pbxproj` (search the file for
   `PrivacyInfo.xcprivacy in Resources`). It declares no tracking, no data collection, and the
   Required-Reason API reasons (UserDefaults CA92.1 / FileTimestamp C617.1 / DiskSpace E174.1 /
   SystemBootTime 35F9.1). Update it if new plugins add data collection or new required-reason APIs.

5. **App icon has no alpha** (App Store rejects alpha on the 1024 icon):
   `sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
   → must be `no`. If icon changed, regenerate with `dart run flutter_launcher_icons`
   (config in `pubspec.yaml`, `remove_alpha_ios: true`).

6. **Monetization state matches intent.** For a free release,
   `MonetizationConfig.subscriptionEnabled` (`lib/core/monetization/monetization_config.dart`)
   must be `false` (all content open, no paywall, no IAP calls, no data collection).

7. **Code is green.** `flutter analyze` (0 issues) and `flutter test` (all pass).

8. **Project still parses after any pbxproj edit:** `xcodebuild -list -project ios/Runner.xcodeproj`.

## Build (user runs on their Mac; needs their signing)

- Bump the build number first (step 2).
- `flutter build ipa` → open `build/ios/archive/Runner.xcarchive` in Xcode Organizer, or
  `open ios/Runner.xcworkspace` and Product ▸ Archive.
- Distribute App ▸ App Store Connect ▸ Upload.

## Human manual steps (print these — Claude cannot do them)

- **Signing**: Xcode ▸ Runner ▸ Signing & Capabilities: Team is `XX24WCN326`, automatic signing.
- **App Store Connect** (https://appstoreconnect.apple.com):
  1. My Apps ▸ + ▸ New App. Bundle ID = `jp.co.shipitenglish.app` (register it under
     Certificates, Identifiers & Profiles first if it is not in the dropdown).
  2. Pricing and Availability: **Free**.
  3. **App Privacy**: answer **"Data Not Collected"** (matches the privacy manifest / no network).
  4. Screenshots (6.7" + 6.5" iPhone; iPad not required — app is iPhone-only), description,
     keywords, support URL, **privacy policy URL** (required).
  5. Age rating questionnaire.
  6. Select the uploaded build ▸ Submit for Review.
- **For a free MVP** there are no in-app purchases to configure. When monetizing later, follow
  `docs/subscription_setup_guide.md` and flip `subscriptionEnabled = true`.

## Notes

- Android `applicationId` is still `com.example.ship_it_english`; only fix that if distributing
  on Google Play (not needed for App Store).
