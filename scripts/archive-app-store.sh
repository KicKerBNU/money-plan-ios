#!/usr/bin/env bash
# Create a Release archive for App Store upload.
# Build number is bumped automatically by the MoneyPlan scheme archive pre-action.
#
# Usage:
#   ./scripts/archive-app-store.sh
#
# Before a new App Store version line (e.g. 1.0.1 → 1.0.2):
#   ./scripts/bump-ios-version.sh --marketing 1.0.2
#   ./scripts/archive-app-store.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xcodegen generate

ARCHIVE_PATH="${ROOT}/build/MoneyPlan.xcarchive"
mkdir -p "${ROOT}/build"

echo "Archiving MoneyPlan → ${ARCHIVE_PATH}"
echo "(Build number will auto-increment via scheme pre-action)"

xcodebuild -project MoneyPlan.xcodeproj \
  -scheme MoneyPlan \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo ""
echo "Archive created: ${ARCHIVE_PATH}"
echo "Next: Xcode → Window → Organizer → Distribute App → App Store Connect → Upload"
