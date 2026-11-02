#!/usr/bin/env bash
# Runs MoneyPlan unit + UI tests (mirrors frontend yarn test:ci).
# Requires: xcodegen, Xcode, Java (Auth emulator), simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== iOS tests (unit + UI) ==="
echo "Generating Xcode project..."
xcodegen generate

FRONTEND_ROOT="$(cd "$ROOT/../money-plan-frontend" && pwd)"
AUTH_HOST="${FIREBASE_AUTH_EMULATOR_HOST:-127.0.0.1:9099}"

cleanup() {
  if [[ -n "${EMULATOR_PID:-}" ]]; then
    kill "$EMULATOR_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Git GUI / pre-commit hooks often lack interactive-shell PATH (nvm).
ensure_node_path() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    nvm use default >/dev/null 2>&1 || nvm use node >/dev/null 2>&1 || true
  fi
  if ! command -v node >/dev/null 2>&1; then
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
  fi
  if ! command -v node >/dev/null 2>&1; then
    echo "node not found on PATH (needed for Firebase Auth emulator)." >&2
    exit 1
  fi
}

start_auth_emulator() {
  ensure_node_path
  cd "$FRONTEND_ROOT"
  local firebase_bin="$FRONTEND_ROOT/node_modules/.bin/firebase"
  if [[ -x "$firebase_bin" ]]; then
    exec "$firebase_bin" emulators:start --only auth --project money-plan-23efb
  fi
  if command -v yarn >/dev/null 2>&1; then
    exec yarn firebase emulators:start --only auth --project money-plan-23efb
  fi
  if command -v npx >/dev/null 2>&1; then
    exec npx --no-install firebase emulators:start --only auth --project money-plan-23efb
  fi
  echo "firebase CLI not found. Run: cd ../money-plan-frontend && yarn install" >&2
  exit 1
}

echo "Starting Firebase Auth emulator on ${AUTH_HOST}..."
(
  start_auth_emulator
) >/tmp/money-plan-ios-auth-emulator.log 2>&1 &
EMULATOR_PID=$!

for i in $(seq 1 60); do
  if curl -sf "http://${AUTH_HOST}/emulator/v1/projects/money-plan-23efb/config" >/dev/null; then
    echo "Auth emulator ready."
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "BUILD FAILED: Auth emulator did not start. See /tmp/money-plan-ios-auth-emulator.log"
    exit 1
  fi
  sleep 1
done

DESTINATION="${IOS_SIMULATOR_DESTINATION:-platform=iOS Simulator,name=iPhone 15,OS=17.0}"

echo "Running MoneyPlanTests + MoneyPlanUITests..."
set +e
xcodebuild test \
  -project MoneyPlan.xcodeproj \
  -scheme MoneyPlan \
  -destination "$DESTINATION" \
  -only-testing:MoneyPlanTests \
  -only-testing:MoneyPlanUITests \
  FIREBASE_AUTH_EMULATOR_HOST="$AUTH_HOST" \
  | tee /tmp/money-plan-ios-tests.log
STATUS=${PIPESTATUS[0]}
set -e

if [[ "$STATUS" -ne 0 ]]; then
  echo ""
  echo "================================================================"
  echo "BUILD FAILED: iOS unit/UI tests are breaking."
  echo "Fix failing XCTest / XCUITest cases, then re-run:"
  echo "  ./scripts/run-ios-tests.sh"
  echo "================================================================"
  exit "$STATUS"
fi

echo "iOS unit + UI tests passed."
