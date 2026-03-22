#!/usr/bin/env bash
# cleanup.sh: Deleta agressivamente tudo que NAO for arquivo .md 
# no diretorio de output, incluindo todas as subpastas.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <output-dir>" >&2
  exit 1
fi

OUTPUT_DIR="$1"

if [ ! -d "$OUTPUT_DIR" ]; then
  echo "[error] Directory not found: $OUTPUT_DIR" >&2
  exit 1
fi

echo "[info] Cleaning up aggressively in $OUTPUT_DIR (keeping only .md files)..."

# 1. Remover todas as subpastas (frames, input, review_keyframes, etc.)
find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
echo "[ok] Subdirectories removed."

# 2. Remover arquivos que nao terminam em .md
# Nota: o ! -name "*.md" garante que mantemos os arquivos de resumo e pack de revisao.
find "$OUTPUT_DIR" -maxdepth 1 -type f ! -name "*.md" -delete
echo "[ok] Non-MD files removed."

echo "[ok] Cleanup finished. Only .md files remain in $OUTPUT_DIR."
