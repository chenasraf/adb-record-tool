#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARAMS_FILE="${SCRIPT_DIR}/.record-adb-params"

# Utility to parse flags
parse_args() {
  SCREEN_SIZE=""
  OUTPUT_NAME="screencast"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --size | -s)
      SCREEN_SIZE="$2"
      shift 2
      ;;
    --output | -o)
      OUTPUT_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 record|finalize [--size <num>] [--output <name>]"
      exit 1
      ;;
    esac
  done

  if [[ -z "${DEVICE_ID:-}" ]]; then
    echo "Available devices:"
    adb devices | tail -n +2 | awk 'NF {print "- " $1}'
    echo ""
    read -rp "Enter device ID to use with adb: " DEVICE_ID
  fi

  if [[ -z "$SCREEN_SIZE" ]]; then
    echo "📏 Detecting resolution..."
    SIZE_LINE=$(adb -s "$DEVICE_ID" shell wm size | grep 'Physical size')
    if [[ $SIZE_LINE =~ ([0-9]+)x([0-9]+) ]]; then
      WIDTH="${BASH_REMATCH[1]}"
      HEIGHT="${BASH_REMATCH[2]}"
      RESOLUTION="${WIDTH}x${HEIGHT}"
    else
      echo "❌ Could not detect resolution"
      exit 1
    fi
  else
    RESOLUTION="${SCREEN_SIZE}x${SCREEN_SIZE}"
  fi

  MP4_NAME="${OUTPUT_NAME}.mp4"
  REMOTE_PATH="/sdcard/${MP4_NAME}"
}

# ✳️ RECORD MODE
if [[ "${1:-}" == "record" ]]; then
  shift
  parse_args "$@"

  echo "🎥 Starting recording on $DEVICE_ID at $RESOLUTION"
  echo "(Press Ctrl+C to stop. Then run: $0 finalize)"
  echo "DEVICE_ID=$DEVICE_ID" >"$PARAMS_FILE"
  echo "REMOTE_PATH=$REMOTE_PATH" >>"$PARAMS_FILE"
  echo "MP4_NAME=$MP4_NAME" >>"$PARAMS_FILE"

  adb -s "$DEVICE_ID" shell screenrecord --size "$RESOLUTION" "$REMOTE_PATH"

  echo "🛑 Recording ended. Run: $0 finalize"
  exit 0
fi

# ✅ FINALIZE MODE
if [[ "${1:-}" == "finalize" ]]; then
  if [[ ! -f "$PARAMS_FILE" ]]; then
    echo "❌ No previous recording found. Run '$0 record' first."
    exit 1
  fi

  source "$PARAMS_FILE"
  echo "📥 Pulling $MP4_NAME from $DEVICE_ID..."
  adb -s "$DEVICE_ID" pull "$REMOTE_PATH" && echo "✅ Pulled to $MP4_NAME"

  echo "🧹 Cleaning up remote file..."
  adb -s "$DEVICE_ID" shell rm -f "$REMOTE_PATH" && echo "✅ Deleted from device"

  rm -f "$PARAMS_FILE"
  exit 0
fi

# ✅ COMPRESS MODE
if [[ "${1:-}" == "compress" ]]; then
  shift
  OUTPUT_NAME=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --output | -o)
      OUTPUT_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 compress [--output <name>]"
      exit 1
      ;;
    esac
  done

  if [[ -z "$OUTPUT_NAME" ]]; then
    if [[ -f "$PARAMS_FILE" ]]; then
      source "$PARAMS_FILE"
    else
      echo "❌ No previous recording found. Run with --output to specify the file."
      exit 1
    fi
  fi

  INPUT_FILE="${MP4_NAME:-${OUTPUT_NAME}.mp4}"
  COMPRESSED_FILE="${INPUT_FILE%.mp4}_compressed.mp4"

  echo "🎞️ Compressing $INPUT_FILE → $COMPRESSED_FILE..."
  ffmpeg -i "$INPUT_FILE" -vcodec libx264 -crf 28 -preset slow -acodec aac -b:a 128k "$COMPRESSED_FILE"

  echo "✅ Compressed file saved as $COMPRESSED_FILE"
  exit 0
fi

# If not a valid command
echo "Usage:"
echo "  $0 record [--size <num>] [--output <name>]"
echo "  $0 finalize"
echo "  $0 compress [--output <name>]"
exit 1
