#!/usr/bin/env bash
# Encodes App Preview frame sequences to Apple-compliant H.264 .mov files.
# Spec: https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PREVIEW_ROOT="AppStorePreviews/iPhone-6.5"
FPS=30
DURATION=20.00
WIDTH=886
HEIGHT=1920

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required. Install with: brew install ffmpeg"
  exit 1
fi

encode_preview() {
  local name="$1"
  local frames_dir="${PREVIEW_ROOT}/frames/${name}"
  local output="${PREVIEW_ROOT}/${name}.mov"

  if [[ ! -d "$frames_dir" ]]; then
    echo "Missing frames: $frames_dir (run GenerateAppPreviewsTests first)"
    exit 1
  fi

  echo "Encoding ${output} …"
  # Apple requires a stereo AAC track even when the preview is silent.
  # Missing audio (-an) triggers: "unsupported or corrupted audio".
  ffmpeg -y -hide_banner -loglevel warning \
    -framerate "$FPS" \
    -i "${frames_dir}/frame_%05d.png" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
    -vf "scale=${WIDTH}:${HEIGHT}:flags=lanczos,format=yuv420p" \
    -c:v libx264 \
    -profile:v high \
    -level:v 4.0 \
    -pix_fmt yuv420p \
    -b:v 11M \
    -minrate 10M \
    -maxrate 12M \
    -bufsize 24M \
    -r "$FPS" \
    -g "$FPS" \
    -c:a aac \
    -b:a 256k \
    -ac 2 \
    -ar 48000 \
    -map 0:v:0 \
    -map 1:a:0 \
    -shortest \
    -movflags +faststart \
    -t "$DURATION" \
    "$output"

  validate_preview "$output"
}

validate_preview() {
  local file="$1"
  echo "Validating ${file} …"

  local wh duration fps vcodec acodec channels sample_rate
  wh=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$file")
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$file")
  vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file")
  acodec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file")
  channels=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$file")
  sample_rate=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$file")

  if [[ "$wh" != "${WIDTH}x${HEIGHT}" ]]; then
    echo "FAIL: resolution is ${wh}, expected ${WIDTH}x${HEIGHT}"
    exit 1
  fi

  if [[ "$vcodec" != "h264" ]]; then
    echo "FAIL: video codec is ${vcodec}, expected h264"
    exit 1
  fi

  if [[ -z "$acodec" || "$acodec" != "aac" ]]; then
    echo "FAIL: audio codec is '${acodec}', expected aac (stereo silent track required by Apple)"
    exit 1
  fi

  if [[ "$channels" != "2" ]]; then
    echo "FAIL: audio channels is ${channels}, expected 2 (stereo)"
    exit 1
  fi

  if [[ "$sample_rate" != "48000" && "$sample_rate" != "44100" ]]; then
    echo "FAIL: audio sample rate is ${sample_rate}, expected 48000 or 44100"
    exit 1
  fi

  # Duration must be 15–30s; stay safely at 20s.
  awk -v d="$duration" 'BEGIN {
    if (d < 15.0 || d > 30.0) { exit 1 }
  }' || {
    echo "FAIL: duration ${duration}s outside 15–30s"
    exit 1
  }

  echo "OK: ${file} — ${wh}, ${duration}s, ${fps}, video=${vcodec}, audio=${acodec} stereo ${sample_rate}Hz"
}

mkdir -p "$PREVIEW_ROOT"

encode_preview "preview-01-track-spending"
encode_preview "preview-02-income-accounts"
encode_preview "preview-03-ai-assistant"

echo ""
echo "Upload these 3 files to App Store Connect → iPhone 6.5\" → App Previews:"
ls -1 "${PREVIEW_ROOT}"/*.mov
