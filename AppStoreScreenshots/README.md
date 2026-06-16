# App Store screenshots

Generated marketing PNGs for App Store Connect. Re-run:

```bash
./scripts/generate-app-store-screenshots.sh
```

## Upload mapping

| Folder | App Store Connect slot | Size (portrait) |
|--------|------------------------|-----------------|
| `iPhone-6.5/` | iPhone 6.5" Display | 1284 × 2778 |
| `iPhone-6.7/` | iPhone 6.7" Display | 1290 × 2796 |
| `iPad-12.9/` | iPad Pro 12.9" | 2048 × 2732 |

| # | Screen |
|---|--------|
| 01 | Expenses list |
| 02 | Income |
| 03 | AI chatbot |
| 04 | Accounts |
| 05 | Login (Email, Apple, Google) |
| 06 | Add expense form |
| 07 | Overview & chart |
| 08 | Spending stats |
| 09 | Category filters |
| 10 | Theme & currency settings |

Upload **01–03** first (used on the App Store install sheet). Use **04–10** to fill the remaining slots (up to 10 per size).

## App Previews (videos)

Previews use a **different resolution** than screenshots: **886 × 1920** for iPhone 6.5".

```bash
./scripts/generate-app-store-previews.sh
```

See `AppStorePreviews/COMPLIANCE.md` for Apple’s strict rules and rejection checklist.
