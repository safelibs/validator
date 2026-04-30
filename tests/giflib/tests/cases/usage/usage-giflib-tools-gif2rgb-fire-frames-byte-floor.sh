#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-frames-byte-floor
# @title: gif2rgb fire output spans at least one full frame
# @description: Decodes the largest fixture fire.gif with gif2rgb -1, reads its width and height from giftext, and asserts the produced RGB byte stream contains at least one full frame worth of pixels (width*height*3 bytes) and is an exact multiple of the per-row stride.
# @timeout: 60
# @tags: usage, cli, gif2rgb, geometry
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# fire.gif is the largest GIF fixture in pic/ at over 20 KiB; this assertion
# anchors the byte-count floor to the actual screen dimensions.
giftext "$gif" >"$tmpdir/info.txt"
size_line=$(grep -E 'Screen Size - Width = [0-9]+, Height = [0-9]+' "$tmpdir/info.txt" | head -n1)
[[ -n "$size_line" ]] || { printf 'no Screen Size in giftext output\n' >&2; exit 1; }
width=$(printf '%s' "$size_line"  | sed -n 's/.*Width = \([0-9]*\).*/\1/p')
height=$(printf '%s' "$size_line" | sed -n 's/.*Height = \([0-9]*\).*/\1/p')
(( width > 0 && height > 0 ))

gif2rgb -1 -o "$tmpdir/fire.rgb" "$gif"
rgb_bytes=$(wc -c <"$tmpdir/fire.rgb")
floor=$(( width * height * 3 ))
stride=$(( width * 3 ))

if (( rgb_bytes < floor )); then
  printf 'expected at least %d bytes (one full %dx%d frame), got %d\n' \
    "$floor" "$width" "$height" "$rgb_bytes" >&2
  exit 1
fi
if (( rgb_bytes % stride != 0 )); then
  printf 'gif2rgb output %d bytes not a multiple of stride %d\n' "$rgb_bytes" "$stride" >&2
  exit 1
fi
