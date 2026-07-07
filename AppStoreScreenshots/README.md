# App Store screenshots

Marketing PNGs for App Store Connect — gradient background, headline, and phone mockup.

Regenerate after UI or copy changes:

```bash
./scripts/generate-app-store-screenshots.sh
```

## Which folder to upload (important)

App Store Connect rejected **1290 × 2796** if you upload to the **6.5" Display** slot. That slot only accepts:

| Portrait size | Upload from |
|---------------|-------------|
| **1284 × 2778** | **`iPhone-6.5/`** ← use this (most common) |
| **1242 × 2688** | **`iPhone-6.5-legacy/`** (if Connect asks for this size) |

| Portrait size | Upload from |
|---------------|-------------|
| **1290 × 2796** | **`iPhone-6.7/`** — 6.7" Display slot (also accepted on 6.9") |
| **1320 × 2868** | **`iPhone-6.9/`** — **6.9" Display** slot (recommended for Pro Max) |

**If you see “dimensions are wrong”:** you likely uploaded the wrong folder to a slot (e.g. `iPhone-6.7/` into **6.5"**). Match folder to the size Connect lists in that tab.

Verify any file:

```bash
sips -g pixelWidth -g pixelHeight AppStoreScreenshots/iPhone-6.5/01-expenses.png
# pixelWidth: 1284
# pixelHeight: 2778
```

## Recommended upload order

| # | File | Style |
|---|------|--------|
| 01 | `01-expenses.png` | Hero — floating cards + value prop |
| 02 | `02-chatbot.png` | Phone — AI assistant |
| 03 | `03-accounts.png` | Phone — accounts |
| 04 | `04-income.png` | Phone — income |
| 05 | `05-overview.png` | Phone — charts & insights |

Optional: `11-expenses-phone.png`, then 06–10.

## App Store Connect steps

1. **App Store Connect** → **Money Plann** → **App Store** → version draft (e.g. 1.0.2).
2. **Previews and Screenshots** → **iPhone 6.5" Display** (or the slot that lists 1284 × 2778).
3. Upload PNGs from **`AppStoreScreenshots/iPhone-6.5/`** in order above.
4. If you also have a **6.9" Display** section, upload **`iPhone-6.9/`** (1320 × 2868) — up to 10 PNGs + 3 app previews.
5. If you also have a **6.7" Display** section, upload **`iPhone-6.7/`** there separately.
6. **Save** → submit for review (no new app binary needed for screenshots only).

## All generated sizes

| Folder | Portrait pixels | Connect slot |
|--------|-----------------|--------------|
| `iPhone-6.5/` | 1284 × 2778 | 6.5" Display |
| `iPhone-6.5-legacy/` | 1242 × 2688 | 6.5" (legacy) |
| `iPhone-6.7/` | 1290 × 2796 | 6.7" Display (also valid on 6.9") |
| `iPhone-6.9/` | 1320 × 2868 | **6.9" Display** (Pro Max — recommended) |
| `iPad-12.9/` | 2048 × 2732 | iPad Pro 12.9" |

## App Previews (videos)

```bash
./scripts/generate-app-store-previews.sh
```

See `AppStorePreviews/COMPLIANCE.md`.
