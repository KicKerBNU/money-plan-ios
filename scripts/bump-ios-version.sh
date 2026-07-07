#!/usr/bin/env bash
# Updates iOS version numbers in project.yml and regenerates MoneyPlan.xcodeproj.
#
# Usage:
#   ./scripts/bump-ios-version.sh                    # increment build number only
#   ./scripts/bump-ios-version.sh --marketing 1.0.2  # new App Store version (marketing only; archive pre-action bumps build)
#   ./scripts/bump-ios-version.sh --build 10         # set build number explicitly
#   ./scripts/bump-ios-version.sh --dry-run
#
# Product → Archive also runs ./scripts/bump-ios-version.sh automatically (see project.yml scheme pre-action).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_YML="${ROOT}/project.yml"
DRY_RUN=0
MARKETING=""
BUILD=""
MARKETING_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --marketing)
      MARKETING="$2"
      MARKETING_ONLY=1
      shift 2
      ;;
    --build)
      BUILD="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$PROJECT_YML" ]]; then
  echo "Missing project.yml at ${PROJECT_YML}" >&2
  exit 1
fi

read_yaml_value() {
  local key="$1"
  grep -E "^[[:space:]]*${key}:" "$PROJECT_YML" | head -1 | sed -E 's/.*: "([^"]+)".*/\1/'
}

CURRENT_MARKETING="$(read_yaml_value MARKETING_VERSION)"
CURRENT_BUILD="$(read_yaml_value CURRENT_PROJECT_VERSION)"

if [[ -z "$CURRENT_MARKETING" || -z "$CURRENT_BUILD" ]]; then
  echo "Could not read MARKETING_VERSION or CURRENT_PROJECT_VERSION from project.yml" >&2
  exit 1
fi

NEXT_MARKETING="${CURRENT_MARKETING}"
NEXT_BUILD="${CURRENT_BUILD}"

if [[ -n "$MARKETING" ]]; then
  NEXT_MARKETING="$MARKETING"
fi

if [[ -n "$BUILD" ]]; then
  NEXT_BUILD="$BUILD"
elif [[ "$MARKETING_ONLY" -eq 0 ]]; then
  NEXT_BUILD=$((CURRENT_BUILD + 1))
fi

echo "iOS version: ${CURRENT_MARKETING} (${CURRENT_BUILD}) → ${NEXT_MARKETING} (${NEXT_BUILD})"

if [[ "$DRY_RUN" -eq 1 ]]; then
  exit 0
fi

apply_sed() {
  local pattern="$1"
  local file="$2"
  if sed --version >/dev/null 2>&1; then
    sed -i "$pattern" "$file"
  else
    sed -i '' "$pattern" "$file"
  fi
}

if [[ "$NEXT_MARKETING" != "$CURRENT_MARKETING" ]]; then
  apply_sed "s/MARKETING_VERSION: \"${CURRENT_MARKETING}\"/MARKETING_VERSION: \"${NEXT_MARKETING}\"/" "$PROJECT_YML"
fi

if [[ "$NEXT_BUILD" != "$CURRENT_BUILD" ]]; then
  apply_sed "s/CURRENT_PROJECT_VERSION: \"${CURRENT_BUILD}\"/CURRENT_PROJECT_VERSION: \"${NEXT_BUILD}\"/" "$PROJECT_YML"
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found. Install: brew install xcodegen" >&2
  exit 1
fi

(cd "$ROOT" && xcodegen generate)

echo "Done. Next archive will ship as ${NEXT_MARKETING} (${NEXT_BUILD}) unless the archive pre-action increments build again."
