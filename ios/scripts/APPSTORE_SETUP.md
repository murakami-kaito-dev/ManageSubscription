# App Store Connect / TestFlight — setup & upload

The upload script (`upload_to_appstore.sh`) automates **build → validate →
upload**. This doc records the finalized config and the one-time human steps.

## Finalized configuration ✅

| Item | Value |
|---|---|
| **App (store) name** | サブスク家計簿 |
| **Bundle ID** | `com.submana.app` (applied to all Xcode configs; `…app.RunnerTests` for tests) |
| **Team ID** | `XX24WCN326` |
| **Issuer ID** | in `ios/AppStoreConnectKeyIdIssuerId.json` (confirmed real) |
| **API Key ID / .p8** | `ios/AuthKey_B5TW9QHTS7.p8` (git-ignored) |
| **SKU** (internal) | `subsc-001` |
| **Primary language** | Japanese (ja) |
| **Apple Developer Program** | enrolled |

Credentials (`.p8`, `AppStoreConnect*.json`) are git-ignored in both the repo
root and `ios/.gitignore`.

## One-time human steps (require your Apple ID / a live account change)

1. **Sign in to Xcode** (the unavoidable 2FA step):
   Xcode → **Settings → Accounts → +** → your Apple ID.
   Then `ios/Runner.xcworkspace` → target **Runner** → **Signing & Capabilities**
   → **Automatically manage signing** → Team **XX24WCN326**. Xcode registers the
   App ID for `com.submana.app` and creates the provisioning profile.

2. **Create the App Store Connect app record**:
   App Store Connect → **Apps → + → New App** — Platform iOS, Bundle ID
   `com.submana.app`, name **サブスク家計簿**, primary language Japanese, SKU
   `subsc-001`.
   - (Claude can create this via the App Store Connect API on request; it's a
     live account change, so Claude will confirm first.)

## Ship it (Claude can run this)

```bash
ios/scripts/upload_to_appstore.sh --validate-only   # dry run
ios/scripts/upload_to_appstore.sh                   # build + validate + upload
```
Once steps 1–2 exist, this runs unattended. The build appears in TestFlight
after Apple processing (≈5–30 min).

## Known pre-submission gaps (not blocking a TestFlight upload, but needed before App Store review)
- **Privacy manifest** `ios/Runner/PrivacyInfo.xcprivacy` is **absent**. Apple
  requires it for App Store review (esp. with AdMob / RevenueCat / required-reason
  APIs). Create before submitting for review.
- Screenshots, description, keywords, support URL, **privacy policy URL**, and the
  age-rating questionnaire are required in App Store Connect before review.
