# Money Plan — iOS

Native SwiftUI iOS app for [Money Plan](../money-plan-frontend), sharing the same Firebase Auth and Railway backend API.

## App Store status

| | |
|---|---|
| **Status** | **Live on the App Store** |
| **Version** | 1.0.0 |
| **App Store** | *(add public URL from App Store Connect → App Information → Apple ID)* |
| **Bundle ID** | `com.moneyplann.app` |
| **Category** | Finance |
| **Pricing** | Free |
| **Privacy policy** | [moneyplann.com/privacy](https://www.moneyplann.com/privacy) |
| **Support** | [moneyplann.com/faq](https://www.moneyplann.com/faq) |

The app is **live on the App Store** (v1.0.0). For metadata updates (keywords, description), create version **1.0.1** — see **[APP_STORE.md](./APP_STORE.md#30-where-to-find-keywords-not-under-app-information)**.

**Organic growth (ASO + SEO):** see **[`../ORGANIC_GROWTH.md`](../ORGANIC_GROWTH.md)** for App Store, Play Store, and web checklist.

**App Review demo account:** credentials are **not** in this repo. Use **App Store Connect → App Information → App Review Information → Sign-In Information** (and your team password manager). Re-seed: `money-plan-backend/scripts/create-demo-account.ts` (`scripts/demo-account.env.example`).

## Features (parity with web app)

| Screen | Description |
|--------|-------------|
| **Login** | Email/password sign-in & sign-up, Google Sign-In, light/dark theme |
| **Overview** | Week/month/year dashboard, KPIs, Swift Charts bar chart, insights |
| **Expenses** | Current-month list, search, category & date filters, reorder, CRUD |
| **Stats** | Monthly category totals and ranked lineup |
| **Income** | Quick-add form, recent entries, edit/delete |
| **Accounts** | Balances, create/rename/delete, drag-to-set-default |
| **Chatbot** | AI expense assistant (`POST /v1/ai/expense-chat`) |

## Requirements

- Xcode 16+ (iOS 17 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Firebase iOS app registered in project `money-plan-23efb`
- Apple Developer team for device/simulator signing

## Setup

1. **Generate the Xcode project**

   ```bash
   cd money-plan-ios
   xcodegen generate
   open MoneyPlan.xcodeproj
   ```

2. **Firebase (required — do not use the `.example` plist)**

   The web app’s Firebase config cannot be reused as-is; iOS needs its own app registration.

   1. Open [Firebase Console → money-plan-23efb → Project settings](https://console.firebase.google.com/project/money-plan-23efb/settings/general).
   2. Under **Your apps**, click **Add app** → **iOS**.
   3. **Bundle ID:** `com.moneyplann.app` (must match the Xcode target).
   4. Download **`GoogleService-Info.plist`** and place it at `MoneyPlan/Resources/GoogleService-Info.plist`.
   5. In Xcode: select the **MoneyPlan** target → **Info** → **URL Types** → add a URL scheme equal to **`REVERSED_CLIENT_ID`** from the plist (required for Google Sign-In).
   6. In Firebase **Authentication → Sign-in method**, ensure **Email/Password** and **Google** are enabled (same as web).

   Until a valid plist is present, the app shows a setup screen instead of crashing. A `GOOGLE_APP_ID` like `1:21904977338:ios:YOUR_IOS_APP_ID` means the template was not replaced.

3. **API base URL**

   Production is baked into `MoneyPlan/Info.plist` (`API_BASE_URL`). For local backend, change it to `http://localhost:3000` and add App Transport Security exception if needed.

4. **Signing**

   Set your **Development Team** in the `MoneyPlan` target.

5. **Run**

   Build and run on simulator or device. Sign in with the same account you use on the web app.

## Architecture

```
MoneyPlan/
├── Core/           # API client, models, auth, theme, date/currency helpers
├── Features/       # SwiftUI screens + @Observable view models (MVVM)
├── Shared/         # Toasts, reusable cards
└── Resources/      # Assets, Localizable.xcstrings, GoogleService-Info.plist
```

- **SwiftUI** + **Observation** (`@Observable`) — no Combine view models
- **async/await** networking mirroring web `apiFetch` (Bearer token, 401 retry, `{ data }` envelope)
- **Optimistic updates** for expense edit/delete/reorder and account reorder (same as web)
- **SF Symbols** for category icons (mapped from web FontAwesome names)
- **String Catalog** (`Localizable.xcstrings`) — keys match web i18n namespaces

## Backend

Uses the same endpoints as `money-plan-frontend`:

- `/v1/expenses`, `/v1/accounts`, `/v1/categories`
- `/v1/incomes`
- `/v1/stats/monthly-expenses`
- `/v1/ai/expense-chat`

Production API: `https://money-plan-backend-production.up.railway.app`

## TestFlight & App Store

**Current:** v1.0.0 is in **Waiting for Review** on the App Store.

See **[APP_STORE.md](./APP_STORE.md)** for the full shipping guide (archive, TestFlight, metadata, privacy, submission). Update the status table at the top of this README when Apple approves or rejects the build.

## Not ported (web-only)

- Public marketing home page & FAQ
- PWA install / service-worker update prompts
- Desktop sidebar layout (iOS uses native `TabView`)
