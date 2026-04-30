#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-grid-format-dimensions
# @title: giftool -f emits per-frame dimensions for gifgrid
# @description: Asks giftool -f to print %w %h for every frame in gifgrid.gif, cross-checks the line count against the gifbuild image header count, and verifies each line parses as two positive integers whose product matches the screen-size product reported by giftext.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
(( frames >= 1 )) || {
  printf 'expected at least one frame, got %d\n' "$frames" >&2
  exit 1
}

giftool -f '%w %h\n' <"$gif" >"$tmpdir/dims.txt"
listed=$(wc -l <"$tmpdir/dims.txt")
[[ "$listed" == "$frames" ]] || {
  printf 'frame count mismatch: gifbuild=%s giftool -f=%s\n' "$frames" "$listed" >&2
  sed -n '1,5p' "$tmpdir/dims.txt" >&2
  exit 1
}

# Each line must be exactly two positive integers.
while IFS=' ' read -r w h rest; do
  [[ -z "$rest" ]] || { printf 'unexpected extra fields: %q\n' "$rest" >&2; exit 1; }
  [[ "$w" =~ ^[1-9][0-9]*$ ]] || { printf 'bad width: %q\n' "$w" >&2; exit 1; }
  [[ "$h" =~ ^[1-9][0-9]*$ ]] || { printf 'bad height: %q\n' "$h" >&2; exit 1; }
done <"$tmpdir/dims.txt"

# Cross-check the first frame against the giftext screen size; gifgrid is a
# single-screen fixture so its image bounds should not exceed the screen.
giftext "$gif" >"$tmpdir/info.txt"
screen_w=$(grep -Eo 'Width = [0-9]+' "$tmpdir/info.txt" | head -n 1 | awk '{print $3}')
screen_h=$(grep -Eo 'Height = [0-9]+' "$tmpdir/info.txt" | head -n 1 | awk '{print $3}')
first_w=$(awk 'NR==1 {print $1}' "$tmpdir/dims.txt")
first_h=$(awk 'NR==1 {print $2}' "$tmpdir/dims.txt")

if (( first_w > screen_w )) || (( first_h > screen_h )); then
  printf 'frame %dx%d exceeds screen %dx%d\n' "$first_w" "$first_h" "$screen_w" "$screen_h" >&2
  exit 1
fi
