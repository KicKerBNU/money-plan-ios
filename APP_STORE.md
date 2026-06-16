# Money Plan iOS — TestFlight & App Store

Step-by-step guide to ship **`com.moneyplann.app`** from archive → TestFlight → App Store.

## Submission status

| Field | Value |
|-------|--------|
| **App** | Money Plan |
| **Bundle ID** | `com.moneyplann.app` |
| **Version** | 1.0.0 |
| **Submitted** | June 8, 2026 |
| **Status** | **Waiting for Review** (App Store Connect) |
| **Pricing** | Free — no in-app purchases |
| **Privacy policy** | https://www.moneyplann.com/privacy |
| **Support URL** | https://www.moneyplann.com/faq |
| **Primary category** | Finance |
| **Subtitle** | Expenses, income & AI chat |

### After approval

1. App Store Connect → **App Store** → version **1.0.0**.
2. Choose **Release this version manually** or **Automatically release**.
3. Update `money-plan-ios/README.md` status to **Live on the App Store** and add the public App Store link when available.

### If rejected

1. Read the resolution center message in App Store Connect.
2. Fix the issue, bump `CURRENT_PROJECT_VERSION` in `project.yml`, archive, upload a new build.
3. Attach the new build to the same or a new App Store version and resubmit.

---

## Prerequisites

| Requirement | Status / action |
|-------------|-----------------|
| **Apple Developer Program** (paid, $99/year) | [developer.apple.com/programs](https://developer.apple.com/programs/) |
| **Bundle ID** `com.moneyplann.app` registered | [Certificates, Identifiers & Profiles → Identifiers](https://developer.apple.com/account/resources/identifiers/list) |
| **Firebase iOS app** with production `GoogleService-Info.plist` | Firebase Console → `money-plan-23efb` |
| **Google Sign-In URL scheme** in `Info.plist` | Already in `project.yml` (REVERSED_CLIENT_ID) |
| **Sign in with Apple** capability on App ID | Enable on the identifier + Xcode entitlements (already in `MoneyPlan.entitlements`) |
| **App icon** 1024×1024 | `MoneyPlan/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| **Privacy Policy URL** (public HTTPS) | https://www.moneyplann.com/privacy |
| **Support URL** | https://www.moneyplann.com/faq |
| **Xcode 16+** with command-line tools | `xcode-select --install` |

---

## Phase 1 — Apple Developer & App Store Connect setup

### 1.1 Register the App ID

1. [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list) → **+** → **App IDs**.
2. **Bundle ID:** `com.moneyplann.app` (Explicit).
3. Enable capabilities:
   - **Sign in with Apple**
   - (Google Sign-In uses URL schemes only — no extra Apple capability)
4. Save.

### 1.2 Create the app in App Store Connect

1. [App Store Connect → Apps](https://appstoreconnect.apple.com/apps) → **+** → **New App**.
2. **Platforms:** iOS  
3. **Name:** Money Plan  
4. **Primary language:** English (U.S.) or Portuguese (Portugal)  
5. **Bundle ID:** `com.moneyplann.app`  
6. **SKU:** e.g. `moneyplan-ios-001` (any unique string you choose)  
7. **User access:** Full access (or limit to your team).

You can create the listing before the first binary upload; metadata can be filled in while TestFlight processes.

### 1.3 Signing in Xcode

1. `cd money-plan-ios && xcodegen generate && open MoneyPlan.xcodeproj`
2. Select **MoneyPlan** target → **Signing & Capabilities**.
3. Check **Automatically manage signing**.
4. Choose your **Team** (Apple Developer account).
5. Confirm **Bundle Identifier** is `com.moneyplann.app`.
6. Build once on a **physical device** to verify signing (simulator does not use distribution profiles).

Optional: set your team in `project.yml` so XcodeGen preserves it:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: YOUR10CHARTEAMID
```

---

## Phase 2 — Archive & upload to TestFlight

### 2.1 Pre-flight checks

- [ ] Production API: default `https://money-plan-backend-production.up.railway.app` (see `APIClient.swift`).
- [ ] Valid `GoogleService-Info.plist` in `MoneyPlan/Resources/` (not `.example`).
- [ ] Sign in with Email, Google, and Apple tested on a **real device**.
- [ ] Version numbers: `MARKETING_VERSION` (user-facing, e.g. `1.0.0`) and `CURRENT_PROJECT_VERSION` (build number, e.g. `1`) in `project.yml`.

**Every new upload** must increase **build number** (`CURRENT_PROJECT_VERSION`). You may keep the same marketing version for TestFlight betas.

### 2.2 Archive (Xcode GUI)

1. Scheme: **MoneyPlan**.
2. Destination: **Any iOS Device (arm64)** — not a simulator.
3. **Product → Archive** (Release configuration).
4. When the Organizer opens, select the archive → **Distribute App**.
5. **App Store Connect** → **Upload**.
6. Options (typical):
   - Include bitcode: N/A (deprecated)
   - Upload symbols: **Yes** (for crash reports)
   - Manage version and build number: Xcode can auto-increment build if configured
7. Wait for upload to finish.

### 2.3 Archive (command line)

```bash
cd money-plan-ios
xcodegen generate

xcodebuild -project MoneyPlan.xcodeproj \
  -scheme MoneyPlan \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/MoneyPlan.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath build/MoneyPlan.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

Create `ExportOptions.plist` for App Store upload:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>upload</string>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
```

Or upload the `.ipa` with **Transporter** (Mac App Store).

### 2.4 TestFlight

1. App Store Connect → your app → **TestFlight**.
2. After processing (~5–30 min), the build appears under **iOS**.
3. **Internal testing:** add App Store Connect users on your team — no Apple review.
4. **External testing:** create a group, add testers (email or public link), submit for **Beta App Review** (lighter than full App Store review).
5. Install via **TestFlight** app on iPhone.

Common upload failures:

| Issue | Fix |
|-------|-----|
| Missing compliance | Answer export encryption in App Store Connect, or set `ITSAppUsesNonExemptEncryption` in Info.plist |
| Invalid signing | Team + distribution certificate in Xcode |
| Bundle ID mismatch | Must match App Store Connect and Firebase |
| Missing icons | 1024×1024 in AppIcon asset |

---

## Phase 3 — App Store submission (after TestFlight)

### 3.1 Required metadata (App Store Connect)

| Field | Notes |
|-------|--------|
| **App name** | Money Plan |
| **Subtitle** | Short tagline (30 chars) |
| **Description** | What the app does (expenses, income, AI assistant) |
| **Keywords** | finance, budget, expenses, … |
| **Support URL** | HTTPS page (help/contact) |
| **Privacy Policy URL** | **Required** — must describe auth, data storage, third parties (Firebase, OpenAI via backend) |
| **Category** | Finance (already `public.app-category.finance` in project) |
| **Age rating** | Questionnaire in Connect |
| **Screenshots** | 6.7", 6.5", 5.5" iPhone sizes (and iPad if supporting iPad) |
| **App Privacy** | Data collection questionnaire (see below) |

### 3.2 App Privacy (nutrition labels)

Declare what the app collects, aligned with actual behavior:

| Data | Likely answer |
|------|----------------|
| **Contact info** (email) | Yes — Firebase Auth account |
| **Financial info** | Yes — expenses/income user enters |
| **User ID** | Yes — Firebase UID |
| **Usage data** | If Firebase Analytics enabled — Yes, analytics |
| **Data linked to user** | Yes |
| **Third parties** | Firebase (Google), your backend API (Railway), OpenAI (via backend for chat only) |

Review [Firebase data disclosure](https://firebase.google.com/support/guides/app-store-data-disclosure) and your backend privacy policy.

### 3.3 Export compliance (encryption)

The app uses HTTPS only (standard TLS). In App Store Connect, when asked about encryption:

- **Uses encryption:** Yes  
- **Exempt:** Yes (only standard HTTPS / Apple's APIs)

`ITSAppUsesNonExemptEncryption = false` is set in the project Info.plist to skip the repeated upload prompt.

### 3.4 Sign in with Apple

Apple requires **Sign in with Apple** if you offer Google (or other third-party) login — already implemented in `LoginView` + entitlements. Ensure the capability is enabled on the App ID in the Developer portal.

### 3.5 Review notes (App Store Connect)

Paste the block below into **App Review Information → Notes**. Put the demo password in **Sign-In Information** as well (same value in both places).

```
Money Plan — App Review notes

Money Plan is a personal finance app. Every screen and feature requires sign-in, including the Expense assistant (Chat tab). There is no guest mode and no feature works without an account.

This app is account-based under Guideline 5.1.1: expenses, income, accounts, overview, and the Expense assistant all read and write the signed-in user's private financial data on our server. Registration is required because the product cannot function without identifying the user and loading their data.

DEMO ACCOUNT (recommended for review)
Email: appstore.review@moneyplann.com
Password: [same password as in the Sign-In Information field above]

This account already includes sample expenses, income, and accounts so you can test all features immediately.

HOW TO TEST
1. Open the app — you will see the sign-in screen first (required).
2. Sign in with the demo email and password (or Sign in with Apple / Google if you prefer).
3. Expenses — view list, filters, and add an expense (+).
4. Income — view and add income entries.
5. Accounts — view multiple accounts and balances.
6. Chat (Expense assistant) — this tab is only available after sign-in. Ask: "How much did I spend on food this month?" The reply is generated from this demo account's logged expense data via our backend. It is not a general-purpose AI chatbot.

EXPENSE ASSISTANT (CHAT) — ACCOUNT-BASED ONLY
- Requires login. Without authentication, the app does not show the main tabs and the backend rejects chat requests (no user ID → no expense data).
- Not generic AI chat. The assistant only answers questions about the logged-in user's own expense records (totals, categories, date ranges). It does not answer general knowledge, jokes, or off-topic questions.
- Messages go to our backend API (https://money-plan-backend-production.up.railway.app), which queries that user's data and uses OpenAI to format the answer. No financial advice — summaries from user-entered data only.

REQUIREMENTS
- Internet connection (Firebase Auth + API at https://money-plan-backend-production.up.railway.app).
- iOS 17 or later.

SIGN-IN OPTIONS
- Email/password (use demo account above — easiest for review)
- Sign in with Apple
- Sign in with Google

If you have any issue signing in, please contact us at support@moneyplann.com.
```

**Resolution Center (Guideline 5.1.1 rejection):** If Apple questions login before Chat, reply that the Expense assistant is account-based — it only queries the signed-in user's expense records and cannot work without authentication. Ask reviewers to sign in with the demo account before opening the Chat tab.

**Demo account credentials (for Sign-In Information field):**

| Field | Value |
|-------|--------|
| Email | `appstore.review@moneyplann.com` |
| Password | `MoneyPlan-Review2026!` |

Re-seed sample data if needed: `money-plan-backend/scripts/create-demo-account.ts` (see backend README).

### 3.6 Submit for review

1. App Store Connect → **App Store** tab → **+ Version** (e.g. `1.0.0`).
2. Select the **TestFlight build** you want to release.
3. Complete all required fields and screenshots.
4. **Add for Review** → **Submit to App Review**.

Review usually takes 24–48 hours (can be longer).

---

## Phase 4 — After approval

- **Release manually** or **automatically** when approved.
- Monitor **Crashlytics** / Xcode Organizer crashes if you add crash reporting later.
- For updates: bump `CURRENT_PROJECT_VERSION`, archive again, upload, attach new build to a new App Store version.

---

## Quick reference

| Item | Value |
|------|--------|
| Bundle ID | `com.moneyplann.app` |
| Display name | Money Plan |
| Min iOS | 17.0 |
| Production API | `https://money-plan-backend-production.up.railway.app` |
| Firebase project | `money-plan-23efb` |

## Checklist — first App Store release (v1.0.0)

```
[x] Apple Developer Program active
[x] App ID com.moneyplann.app + Sign in with Apple enabled
[x] App created in App Store Connect
[x] Xcode Team selected, archive uploaded
[x] GoogleService-Info.plist production file in Resources/
[x] Tested login (email, Google, Apple) on device
[x] Privacy policy live at https://www.moneyplann.com/privacy
[x] App Privacy questionnaire published
[x] Primary category: Finance
[x] Screenshots + metadata + demo account
[x] Submitted for App Store review (June 8, 2026)
[ ] Approved by Apple
[ ] Released on the App Store
```
