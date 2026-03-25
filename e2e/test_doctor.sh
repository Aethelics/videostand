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
SANDBOX="$SCRIPT_DIR/sandbox_doctor_$$"

mkdir -p "$SANDBOX"
cd "$SANDBOX"
export HOME="$SANDBOX"

cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

log_info "=== E2E Test: doctor ==="

# Test 1: doctor normal output
log_info "Test 1: doctor output"
OUTPUT=$(node "$VS_BIN" doctor codex 2>&1 || true)
if ! echo "$OUTPUT" | grep -q "VideoStand Doctor"; then
  log_error "doctor output did not contain 'VideoStand Doctor'."
  exit 1
fi

# Test 2: doctor --json output
log_info "Test 2: doctor --json"
OUTPUT_JSON=$(node "$VS_BIN" doctor codex --json)
if ! echo "$OUTPUT_JSON" | grep -q '"doctor": "videostand"'; then
  log_error "doctor --json output is invalid."
  exit 1
fi

log_success "=== OK: doctor tests passed ==="
exit 0
