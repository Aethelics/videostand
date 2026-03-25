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
SANDBOX="$SCRIPT_DIR/sandbox_init_$$"

mkdir -p "$SANDBOX"
cd "$SANDBOX"
export HOME="$SANDBOX"

cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

log_info "=== E2E Test: init ==="

# Test 1: init specific target
log_info "Test 1: init codex"
node "$VS_BIN" init codex
if [ ! -d ".codex/skills/videostand" ]; then
  log_error "Skill directory for codex not created."
  exit 1
fi

# Test 2: init specific target without force (should fail/warn)
log_info "Test 2: init codex (without --force, should fail)"
set +e
node "$VS_BIN" init codex > "$SANDBOX/out.log" 2>&1
EXIT_CODE=$?
set -e
if [ $EXIT_CODE -eq 0 ]; then
  log_error "init codex without --force should have failed."
  exit 1
fi

# Test 3: init specific target with force
log_info "Test 3: init codex --force"
node "$VS_BIN" init codex --force
if [ ! -d ".codex/skills/videostand" ]; then
  log_error "Skill directory for codex not created with --force."
  exit 1
fi

# Test 4: init all (no existing agents)
log_info "Test 4: init all (with no existing agents)"
# Clean up previous codex test to avoid already-exists error
rm -rf .codex
# Create a fake agent dir
mkdir -p .cline
node "$VS_BIN" init all
if [ ! -d ".cline/skills/videostand" ]; then
  log_error "init all did not install to existing .cline directory."
  exit 1
fi

log_success "=== OK: init tests passed ==="
exit 0
