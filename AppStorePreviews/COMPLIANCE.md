# App Store App Previews — compliance checklist (iPhone 6.5")

Official spec: [App preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications)

## Critical: preview size ≠ screenshot size

| Asset | iPhone 6.5" portrait |
|-------|----------------------|
| **Screenshots** | 1284 × 2778 px |
| **App Previews** | **886 × 1920 px** |

Uploading 1284×2778 video to the preview slot is a common rejection cause.

## Technical requirements (must pass)

| Rule | Value |
|------|--------|
| Duration | **15–30 seconds** (we export **20.00s**) |
| Resolution | **886 × 1920** portrait |
| Frame rate | **30 fps** |
| Codec | **H.264** (High profile, level 4.0) |
| Pixel format | **yuv420p** |
| Bit rate | **10–12 Mbps** target |
| Container | `.mov`, `.mp4`, or `.m4v` |
| Max file size | 500 MB |
| Audio | **Required** — stereo **AAC 256 kbps** at **48 kHz** (silent track is fine; **no audio track fails**) |

## Content rules (review rejection triggers)

| Do | Don't |
|----|--------|
| Start on **real in-app UI** (first frame) | Logo splash, black frame, lifestyle footage |
| Show only **app screen captures** | Fingers on screen, over-the-shoulder shots |
| Use **neutral** on-screen copy (if any) | Prices, "Free", "Sale", seasonal dates |
| Show features that **exist in the build** | Unreleased or misleading functionality |
| Keep status bar clean if recording device | Simulator chrome, debug banners |

## Our 3 previews

| File | Story |
|------|--------|
| `preview-01-track-spending.mov` | Expenses → category filters → monthly stats |
| `preview-02-income-accounts.mov` | Income → accounts → overview chart |
| `preview-03-ai-assistant.mov` | AI chat typing demo |

## Generate

```bash
cd money-plan-ios
./scripts/generate-app-store-previews.sh
```

Output: `AppStorePreviews/iPhone-6.5/*.mov`

## Before upload

1. Play each `.mov` — first frame must be app UI.
2. Confirm duration in Finder or with `ffprobe` (15–30s).
3. Upload to **iPhone 6.5" Display → App Previews** (not 6.7" unless you also add that size).
4. Set poster frame in App Store Connect (default is ~5s; pick a clear KPI or list frame).

## If Apple still rejects

- Re-export at exactly **886×1920** (do not upscale from 1080×1920).
- Trim to **≤ 30.00s** (31s fails upload).
- Remove any text overlays added in iMovie/Final Cut.
- Prefer **silent** video if music/voice was flagged.
- Record on a **physical iPhone** (QuickTime → New Movie Recording) if reviewers claim simulator look — then scale/crop to 886×1920 in ffmpeg.
