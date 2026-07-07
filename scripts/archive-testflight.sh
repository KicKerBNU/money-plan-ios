#!/usr/bin/env bash
# Build Money Plan for TestFlight (App Store Connect upload).
# Requires: Xcode with iOS device platform installed (Settings → Components),
#           a signed-in Apple Developer account, and team set in Xcode or project.yml.
#
# Optional override:
#   DEVELOPMENT_TEAM=YOUR10CHARTEAMID ./scripts/archive-testflight.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

read_yaml_team() {
  grep -E '^[[:space:]]*DEVELOPMENT_TEAM:' project.yml | head -1 | sed -E 's/.*: "([^"]*)".*/\1/'
}

TEAM_ID="${DEVELOPMENT_TEAM:-$(read_yaml_team)}"

echo "→ xcodegen"
xcodegen generate

echo "→ Archive (Release, v$(grep MARKETING_VERSION project.yml | head -1 | awk '{print $2}' | tr -d '\"') build $(grep CURRENT_PROJECT_VERSION project.yml | head -1 | awk '{print $2}' | tr -d '\"'))"
mkdir -p build

XCODEBUILD_ARGS=(
  -project MoneyPlan.xcodeproj
  -scheme MoneyPlan
  -configuration Release
  -sdk iphoneos
  -destination 'generic/platform=iOS'
  -archivePath build/MoneyPlan.xcarchive
  CODE_SIGN_STYLE=Automatic
  -allowProvisioningUpdates
)

if [[ -n "$TEAM_ID" ]]; then
  XCODEBUILD_ARGS+=(DEVELOPMENT_TEAM="$TEAM_ID")
fi

xcodebuild "${XCODEBUILD_ARGS[@]}" archive

echo "→ Export IPA"
xcodebuild -exportArchive \
  -archivePath build/MoneyPlan.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates

echo ""
echo "Done. IPA:"
ls -lh build/export/*.ipa
echo ""
echo "Upload with Transporter app, or change ExportOptions.plist destination to 'upload'."
