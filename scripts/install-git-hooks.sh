#!/usr/bin/env bash
# Installs the tracked pre-commit hook into .git/hooks (no git config changes).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

HOOKS_DIR="$ROOT/.git/hooks"
mkdir -p "$HOOKS_DIR"

ln -sfn ../../githooks/pre-commit "$HOOKS_DIR/pre-commit"
chmod +x "$ROOT/githooks/pre-commit"

echo "Installed pre-commit → githooks/pre-commit (runs ./scripts/run-ios-tests.sh)."
