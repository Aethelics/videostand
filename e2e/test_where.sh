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
SANDBOX="$SCRIPT_DIR/sandbox_where_$$"

mkdir -p "$SANDBOX"
cd "$SANDBOX"
export HOME="$SANDBOX"

cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

log_info "=== E2E Test: where ==="

# Test 1: where specific target
log_info "Test 1: where codex"
OUTPUT=$(node "$VS_BIN" where codex)
EXPECTED="$SANDBOX/.codex/skills/videostand"
if ! echo "$OUTPUT" | grep -q "$EXPECTED"; then
  log_error "where codex output ($OUTPUT) did not contain $EXPECTED."
  exit 1
fi

# Test 2: where all
log_info "Test 2: where all"
OUTPUT_ALL=$(node "$VS_BIN" where all)
EXPECTED_CLINE="$SANDBOX/.cline/skills/videostand"
if ! echo "$OUTPUT_ALL" | grep -q "$EXPECTED_CLINE"; then
  log_error "where all output did not contain cline paths."
  exit 1
fi

log_success "=== OK: where tests passed ==="
exit 0
