#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-loop-duration
# @title: ffmpeg WebP loop duration
# @description: Loops a still WebP through ffmpeg with -loop 1 -t to produce a multi-frame MP4 of a known duration and verifies it via ffprobe.
# @timeout: 180
# @tags: usage, webp, video
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
ffmpeg -hide_banner -loglevel error -y -loop 1 -i "$tmpdir/in.webp" \
  -t 1 -r 5 -pix_fmt yuv420p -vf "scale=8:8" \
  -c:v libx264 -preset ultrafast "$tmpdir/out.mp4"
validator_require_file "$tmpdir/out.mp4"

# Pull each stream metric individually so we don't depend on ffprobe's
# field ordering (which differs across versions). default=nokey=1 strips
# everything but the value.
nb_frames=$(ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 \
  "$tmpdir/out.mp4")
duration=$(ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=duration -of default=nokey=1:noprint_wrappers=1 \
  "$tmpdir/out.mp4")
printf 'nb_frames=%s duration=%s\n' "$nb_frames" "$duration"

# nb_frames may be reported as N/A on some muxers; if it is numeric, it
# must equal the expected 5 (5 fps * 1 s).
if [[ "$nb_frames" =~ ^[0-9]+$ ]]; then
  test "$nb_frames" = "5"
fi

# duration must be approximately 1.0 second.
case "$duration" in
  1.0|1.000000|0.99*|1.0*|1.04*) ;;
  *) printf 'unexpected duration: %s\n' "$duration" >&2; exit 1 ;;
esac
