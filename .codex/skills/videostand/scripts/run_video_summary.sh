#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <video.mp4> [output-dir] [model]" >&2
  echo "Env overrides: EVERY_N_FRAMES, INTERVAL_SECONDS, MAX_FRAMES, BATCH_SIZE, VISION_DETAIL, SUMMARY_LANGUAGE, API_BASE, ENV_FILE, ENABLE_AUDIO_TRANSCRIPT, AUDIO_MODEL, AUDIO_LANGUAGE, STRICT_AUDIO, MAX_TRANSCRIPT_CHARS, AUTO_INSTALL_FFMPEG" >&2
  exit 1
fi

INPUT_VIDEO="$1"
OUTPUT_DIR="${2:-./video-summary-$(date +%Y%m%d-%H%M%S)}"
MODEL="${3:-${VIDEO_SUMMARY_MODEL:-gpt-4.1-mini}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMES_DIR="$OUTPUT_DIR/frames"
MANIFEST_PATH="$FRAMES_DIR/frames_manifest.json"
SUMMARY_PATH="$OUTPUT_DIR/video_summary.md"
TRANSCRIPT_PATH="$OUTPUT_DIR/audio_transcript.txt"

has_ffmpeg_tools() {
  command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1
}

ensure_ffmpeg() {
  if has_ffmpeg_tools; then
    return 0
  fi

  local mode="${AUTO_INSTALL_FFMPEG:-ask}"
  local consent="n"

  if [ "$mode" = "always" ]; then
    consent="y"
  elif [ "$mode" = "never" ]; then
    consent="n"
  else
    echo "[warn] ffmpeg/ffprobe nao foram encontrados no ambiente."
    echo "[question] Posso instalar o ffmpeg agora? Vai precisar de permissao de administrador e pode pedir sua senha."
    printf "> [s/N]: "
    local answer=""
    read -r answer || true
    case "${answer,,}" in
      s|sim|y|yes) consent="y" ;;
      *) consent="n" ;;
    esac
  fi

  if [ "$consent" != "y" ]; then
    echo "[error] Nao foi possivel continuar sem ffmpeg/ffprobe." >&2
    exit 1
  fi

  echo "[info] Iniciando instalacao do ffmpeg. O sistema pode solicitar senha de administrador."
  if ! "$SCRIPT_DIR/install_ffmpeg.sh"; then
    echo "[error] Falha na instalacao automatica do ffmpeg." >&2
    exit 1
  fi

  if ! has_ffmpeg_tools; then
    echo "[error] ffmpeg/ffprobe ainda nao estao disponiveis apos a instalacao." >&2
    exit 1
  fi
}

if [ ! -f "$INPUT_VIDEO" ]; then
  echo "Input video not found: $INPUT_VIDEO" >&2
  exit 1
fi

ensure_ffmpeg

mkdir -p "$FRAMES_DIR"

EXTRACT_CMD=(python3 "$SCRIPT_DIR/extract_frames.py" --input "$INPUT_VIDEO" --output-dir "$FRAMES_DIR")

if [ -n "${INTERVAL_SECONDS:-}" ]; then
  EXTRACT_CMD+=(--interval-seconds "$INTERVAL_SECONDS")
else
  EXTRACT_CMD+=(--every-n-frames "${EVERY_N_FRAMES:-15}")
fi

if [ -n "${MAX_FRAMES:-}" ]; then
  EXTRACT_CMD+=(--max-frames "$MAX_FRAMES")
fi

echo "[info] Extracting frames..."
"${EXTRACT_CMD[@]}"

if [ "${ENABLE_AUDIO_TRANSCRIPT:-1}" != "0" ]; then
  TRANS_CMD=(
    python3 "$SCRIPT_DIR/transcribe_audio_openai.py"
    --input "$INPUT_VIDEO"
    --output "$TRANSCRIPT_PATH"
    --model "${AUDIO_MODEL:-gpt-4o-mini-transcribe}"
    --language "${AUDIO_LANGUAGE:-pt}"
  )

  if [ -n "${API_BASE:-}" ]; then
    TRANS_CMD+=(--api-base "$API_BASE")
  fi
  if [ -n "${ENV_FILE:-}" ]; then
    TRANS_CMD+=(--env-file "$ENV_FILE")
  fi

  echo "[info] Transcribing audio..."
  if "${TRANS_CMD[@]}"; then
    echo "[ok] Audio transcript generated."
  else
    TRANS_RC=$?
    if [ "$TRANS_RC" -eq 2 ]; then
      echo "[warn] Video has no audio stream; continuing with visual summary only."
    elif [ "${STRICT_AUDIO:-0}" = "1" ]; then
      echo "[error] Audio transcription failed and STRICT_AUDIO=1." >&2
      exit "$TRANS_RC"
    else
      echo "[warn] Audio transcription failed (rc=$TRANS_RC); continuing with visual summary only."
    fi
  fi
fi

SUM_CMD=(
  python3 "$SCRIPT_DIR/summarize_frames_openai.py"
  --manifest "$MANIFEST_PATH"
  --model "$MODEL"
  --batch-size "${BATCH_SIZE:-12}"
  --detail "${VISION_DETAIL:-low}"
  --language "${SUMMARY_LANGUAGE:-pt-BR}"
  --max-transcript-chars "${MAX_TRANSCRIPT_CHARS:-12000}"
  --output "$SUMMARY_PATH"
)

if [ -n "${API_BASE:-}" ]; then
  SUM_CMD+=(--api-base "$API_BASE")
fi
if [ -n "${ENV_FILE:-}" ]; then
  SUM_CMD+=(--env-file "$ENV_FILE")
fi
if [ -s "$TRANSCRIPT_PATH" ]; then
  SUM_CMD+=(--transcript-file "$TRANSCRIPT_PATH")
fi

echo "[info] Summarizing frames..."
"${SUM_CMD[@]}"

echo "[ok] Done."
echo "[ok] Summary: $SUMMARY_PATH"
