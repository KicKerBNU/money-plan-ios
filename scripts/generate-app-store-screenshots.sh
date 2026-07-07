#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xcodegen generate

DESTINATION="${SCREENSHOT_SIMULATOR:-platform=iOS Simulator,name=iPhone 15 Plus,OS=17.0}"

echo "Generating App Store screenshots → AppStoreScreenshots/"
xcodebuild test \
  -project MoneyPlan.xcodeproj \
  -scheme MoneyPlan \
  -destination "$DESTINATION" \
  -only-testing:MoneyPlanScreenshotTests/GenerateScreenshotsTests/testGenerateAppStoreScreenshots \
  CODE_SIGNING_ALLOWED=NO \
  | xcbeautify 2>/dev/null || xcodebuild test \
  -project MoneyPlan.xcodeproj \
  -scheme MoneyPlan \
  -destination "$DESTINATION" \
  -only-testing:MoneyPlanScreenshotTests/GenerateScreenshotsTests/testGenerateAppStoreScreenshots \
  CODE_SIGNING_ALLOWED=NO

echo ""
echo "Done. Upload these folders to App Store Connect:"
echo "  6.9\" slot (1320×2868):           AppStoreScreenshots/iPhone-6.9/"
echo "  PRIMARY (6.5\" slot, 1284×2778): AppStoreScreenshots/iPhone-6.5/"
echo "  Legacy (1242×2688):              AppStoreScreenshots/iPhone-6.5-legacy/"
echo "  6.7\" slot (1290×2796):           AppStoreScreenshots/iPhone-6.7/"
find AppStoreScreenshots -name '*.png' | sort
