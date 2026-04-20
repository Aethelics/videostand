#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_error()   { echo -e "${RED}✗ $1${NC}"; exit 1; }

# --- Test 1: watch filter includes .avi ---
grep -q '\.avi' "$REPO_ROOT/bin/videostand.js" \
  || log_error "watch filter does not include .avi"
log_success "watch filter includes .avi"

# --- Test 2: watch filter includes .webm ---
grep -q '\.webm' "$REPO_ROOT/bin/videostand.js" \
  || log_error "watch filter does not include .webm"
log_success "watch filter includes .webm"

# --- Test 3: watch filter includes .gif ---
grep -q '\.gif' "$REPO_ROOT/bin/videostand.js" \
  || log_error "watch filter does not include .gif"
log_success "watch filter includes .gif"

# --- Test 4: README documents supported video formats ---
grep -q '\.avi' "$REPO_ROOT/README.md" \
  || log_error "README does not document .avi format"
grep -q '\.webm' "$REPO_ROOT/README.md" \
  || log_error "README does not document .webm format"
grep -q '\.gif' "$REPO_ROOT/README.md" \
  || log_error "README does not document .gif format"
log_success "README documents all supported formats (.avi, .webm, .gif)"

echo ""
echo "Todos os testes passaram."
