# Money Plan iOS — TestFlight & App Store

Step-by-step guide to ship **`com.moneyplann.app`** from archive → TestFlight → App Store.

## Submission status

| Field | Value |
|-------|--------|
| **App** | Money Plan |
| **Bundle ID** | `com.moneyplann.app` |
| **Version** | 1.0.0 |
| **Submitted** | June 8, 2026 |
| **Status** | **Live on the App Store** |
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
- [ ] Version numbers live in **`project.yml`** (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`). `Info.plist` uses `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` — do not hardcode versions there.

**Automatic build bump:** **Product → Archive** runs `scripts/bump-ios-version.sh` as a scheme pre-action and increments **`CURRENT_PROJECT_VERSION`** every time. You do not need to edit the build number manually for each upload.

**New App Store version** (e.g. 1.0.1 → 1.0.2): run once before archiving:

```bash
./scripts/bump-ios-version.sh --marketing 1.0.2
```

Then archive (Xcode or `./scripts/archive-app-store.sh`). CLI archive uses the same pre-action.

**Every new upload** must increase **build number** (`CURRENT_PROJECT_VERSION`). Marketing version only needs to change when shipping a new App Store version line.

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

### 3.0 Where to find Keywords (not under App Information)

Apple puts **Keywords** on the **version listing**, not under **General → App Information**.

#### View keywords on the live version (1.0.0)

1. [App Store Connect → Apps](https://appstoreconnect.apple.com/apps) → **Money Plan**
2. Left sidebar → **Distribution**
3. Under **iOS App**, click **1.0.0** (status: **Ready for Sale** / *Live on the App Store*)
4. Scroll past screenshots to **English (U.S.)** (or your primary locale)
5. **Keywords** is near **Description** and **Promotional Text** (100 characters, comma-separated)

On a **live** version, Keywords is usually **read-only** — you can audit what shipped, not edit in place.

**App Information** (sidebar under General) has name, category, privacy URL, etc. — but **not** Keywords.

**New Connect UI tip:** if the sidebar only shows **1.0.0** without expandable metadata, open that version and use the **locale** row (e.g. **English (U.S.)**) or the **Edit** / pencil control on the product-page section — Keywords is in that block, not under General.

#### Change keywords (app already on the App Store)

Keywords **cannot** be updated on the live 1.0.0 listing. Create a **new App Store version**:

1. **Distribution** → **iOS App** → **+** (or **Add Version**) → **1.0.1**
2. Metadata copies from 1.0.0 — edit **Keywords** on the **1.0.1** draft
3. Attach a **new build** (increment build number in Xcode, archive, upload — Apple requires a build on each version submission)
4. **What's New:** e.g. `Improved App Store discoverability.`
5. Submit **1.0.1** for review

Bundle keyword + description tweaks into one **1.0.1** submission so you only wait on review once.

**Recommended keywords** (97 chars; avoids overlap with subtitle *Expenses, income & AI chat*):

```text
budget,finance,spending,tracker,money,accounts,free,personal,planner,manager,wallet,savings,cash
```

### 3.1 Required metadata (App Store Connect)

| Field | Where | Notes |
|-------|--------|--------|
| **App name** | App Information or version listing | Money Plan |
| **Subtitle** | Version listing (localized) | e.g. `Expenses, income & AI chat` (30 chars) |
| **Description** | Version listing (localized) | What the app does (expenses, income, AI assistant) |
| **Keywords** | Version listing (localized) | See [§3.0](#30-where-to-find-keywords-not-under-app-information) — not App Information |
| **Support URL** | Version listing | HTTPS page (help/contact) |
| **Privacy Policy URL** | App Information | **Required** — auth, data storage, third parties |
| **Category** | App Information | Finance |
| **Age rating** | App Information | Questionnaire in Connect |
| **Screenshots** | Version listing | **6.7"** (required), 6.5", iPad if applicable — see [§3.4](#34-marketing-screenshots--search-visibility) |

### 3.4 Marketing screenshots & search visibility

**Regenerate** (gradient + headline + phone mockup):

```bash
cd money-plan-ios
./scripts/generate-app-store-screenshots.sh
```

Upload PNGs from `AppStoreScreenshots/iPhone-6.7/` first (1290 × 2796). Recommended order: `01-expenses` → `02-chatbot` → `03-accounts` → `04-income` → `05-overview`. Details: `AppStoreScreenshots/README.md`.

**Why search may not show screenshots:** In App Store **search results**, Apple often shows screenshot carousels only for **Search Ads** (labeled “Ad”) or featured placements. **Organic search** frequently shows icon + title only — that is normal. Screenshots always appear on your **product page** after the user taps your app; optimize those first.

**Screenshot-only updates** do not require a new binary — replace images in App Store Connect → Save.
| **App Privacy** | App Privacy (sidebar) | Data collection questionnaire (see below) |

### 3.2 App Privacy (nutrition labels)

Declare what the app collects, aligned with actual behavior:

| Data | Likely answer |
|------|----------------|
| **Contact info** (email) | Yes — Firebase Auth account |
| **Financial info** | Yes — expenses/income user enters |
| **User ID** | Yes — Firebase UID |
| **Usage data** | Yes — Firebase Analytics (product usage: screens, sessions). **Not used for advertising or cross-app tracking.** |
| **Data linked to user** | Yes |
| **Third parties** | Firebase (Google), your backend API (Railway), OpenAI (via backend for chat only) |

Review [Firebase data disclosure](https://firebase.google.com/support/guides/app-store-data-disclosure) and **`ANALYTICS.md`** at the repo root for exact App Privacy answers.

### 3.3 Export compliance (encryption)

The app uses HTTPS only (standard TLS). In App Store Connect, when asked about encryption:

- **Uses encryption:** Yes  
- **Exempt:** Yes (only standard HTTPS / Apple's APIs)

`ITSAppUsesNonExemptEncryption = false` is set in the project Info.plist to skip the repeated upload prompt.

### 3.4 Sign in with Apple

Apple requires **Sign in with Apple** if you offer Google (or other third-party) login — already implemented in `LoginView` + entitlements. Ensure the capability is enabled on the App ID in the Developer portal.

### 3.5 Review notes (App Store Connect)

Paste the block below into **App Review Information → Notes**. Put the demo email and password in **Sign-In Information** only — never commit those values to git.

```
Money Plan — App Review notes

Money Plan is a personal finance app. Every screen and feature requires sign-in, including the Expense assistant (Chat tab). There is no guest mode and no feature works without an account.

This app is account-based under Guideline 5.1.1: expenses, income, accounts, overview, and the Expense assistant all read and write the signed-in user's private financial data on our server. Registration is required because the product cannot function without identifying the user and loading their data.

DEMO ACCOUNT (recommended for review)
Use the email and password entered in App Store Connect Sign-In Information (same account for all reviewers).

This account already includes sample expenses, income, and accounts so you can test all features immediately.

HOW TO TEST
1. Open the app — you will see the sign-in screen first (required).
2. Sign in with the demo email and password (or Sign in with Apple / Google if you prefer).
3. Expenses — view list, filters, and add an expense (+).
4. Income — view and add income entries.
5. Accounts — view multiple accounts and balances.
6. Chat (Expense assistant) — this tab is only available after sign-in. On first open, a "Third-party AI processing" sheet explains what data is sent and that it is shared with OpenAI; tap "Agree and continue" before sending a message. Then ask: "How much did I spend on food this month?" The reply is generated from this demo account's logged expense data via our backend. It is not a general-purpose AI chatbot.

EXPENSE ASSISTANT (CHAT) — ACCOUNT-BASED ONLY
- Requires login. Without authentication, the app does not show the main tabs and the backend rejects chat requests (no user ID → no expense data).
- Not generic AI chat. The assistant only answers questions about the logged-in user's own expense records (totals, categories, date ranges). It does not answer general knowledge, jokes, or off-topic questions.
- Messages go to our backend API (https://money-plan-backend-production.up.railway.app), which queries that user's data and uses OpenAI to format the answer. No financial advice — summaries from user-entered data only.
- IN-APP AI CONSENT (Guideline 5.1.1(i) / 5.1.2(i)): Before the first chat message, the app discloses what data is sent, identifies OpenAI as the processor, and requires "Agree and continue". No data is sent to OpenAI if the user taps "Not now".

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

**Demo account credentials:** enter email and password in App Store Connect **Sign-In Information** only (team password manager for your copy). Do not paste passwords into tracked docs.

Re-seed sample data: `money-plan-backend/scripts/create-demo-account.ts` with local `scripts/demo-account.env` (see `demo-account.env.example`).

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
