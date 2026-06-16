#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xcodegen generate

DESTINATION="${PREVIEW_SIMULATOR:-platform=iOS Simulator,name=iPhone 15 Plus,OS=17.0}"

echo "Step 1/2: Render preview frames (886×1920 × 600 frames × 3 videos)…"
xcodebuild test \
  -project MoneyPlan.xcodeproj \
  -scheme MoneyPlan \
  -destination "$DESTINATION" \
  -only-testing:MoneyPlanScreenshotTests/GenerateAppPreviewsTests/testGenerateAppPreviewFrames \
  CODE_SIGNING_ALLOWED=NO

echo ""
echo "Step 2/2: Encode H.264 .mov files…"
"$(dirname "$0")/encode-app-previews.sh"
