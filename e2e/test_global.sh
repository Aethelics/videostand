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
SANDBOX="$SCRIPT_DIR/sandbox_global_$$"

mkdir -p "$SANDBOX"
cd "$SANDBOX"
# For global test, we set HOME to the sandbox, but test that HOME/.target is used instead of CWD/.target
export HOME="$SANDBOX/fake_home"
mkdir -p "$HOME"

cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

log_info "=== E2E Test: global (-g) ==="

# Test 1: init codex -g
log_info "Test 1: init codex -g"
node "$VS_BIN" init codex -g >/dev/null 2>&1
if [ ! -d "$HOME/.codex/skills/videostand" ]; then
  log_error "init codex -g didn't create directory in HOME."
  exit 1
fi

# Test 2: where codex -g
log_info "Test 2: where codex -g"
OUTPUT=$(node "$VS_BIN" where codex -g)
EXPECTED="$HOME/.codex/skills/videostand"
if ! echo "$OUTPUT" | grep -q "$EXPECTED"; then
  log_error "Output ($OUTPUT) did not contain expected path ($EXPECTED)."
  exit 1
fi

# Test 3: remove codex -g
log_info "Test 3: remove codex -g"
node "$VS_BIN" remove codex -g >/dev/null 2>&1
if [ -d "$HOME/.codex/skills/videostand" ]; then
  log_error "remove codex -g failed."
  exit 1
fi

log_success "=== OK: global tests passed ==="
exit 0
