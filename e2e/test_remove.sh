#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VS_BIN="$SCRIPT_DIR/../bin/videostand.js"
SANDBOX="$SCRIPT_DIR/sandbox_remove_$$"

mkdir -p "$SANDBOX"
cd "$SANDBOX"
export HOME="$SANDBOX"

cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

log_info "=== E2E Test: remove ==="

# Setup: install first
node "$VS_BIN" init codex >/dev/null 2>&1

# Test 1: remove specific target
log_info "Test 1: remove codex"
node "$VS_BIN" remove codex >/dev/null 2>&1
if [ -d ".codex/skills/videostand" ]; then
  log_error "Skill directory for codex was not removed."
  exit 1
fi

# Test 2: remove all
log_info "Test 2: remove all"
node "$VS_BIN" init codex >/dev/null 2>&1
node "$VS_BIN" init cline >/dev/null 2>&1
node "$VS_BIN" remove all >/dev/null 2>&1
if [ -d ".codex/skills/videostand" ] || [ -d ".cline/skills/videostand" ]; then
  log_error "remove all failed."
  exit 1
fi

log_success "=== OK: remove tests passed ==="
exit 0
