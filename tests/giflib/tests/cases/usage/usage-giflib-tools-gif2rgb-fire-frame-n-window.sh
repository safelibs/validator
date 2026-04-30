#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-frame-n-window
# @title: gif2rgb fire interleaved frame window size
# @description: Decodes the multi-frame fire.gif with gif2rgb -1 into a single composited RGB stream and verifies the byte size matches exactly width*height*3 for one composed frame, with at least one non-zero pixel byte present, exercising the gif2rgb interleaved decode path.
# @timeout: 60
# @tags: usage, cli, gif2rgb, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Anchor dimensions from giftool -f.
giftool -f '%n %wx%h\n' <"$gif" >"$tmpdir/frames.txt"
w=$(awk 'NR==1 {split($2, a, "x"); print a[1]; exit}' "$tmpdir/frames.txt")
h=$(awk 'NR==1 {split($2, a, "x"); print a[2]; exit}' "$tmpdir/frames.txt")
[[ "$w" =~ ^[1-9][0-9]*$ ]] || { printf 'bad width: %q\n' "$w" >&2; exit 1; }
[[ "$h" =~ ^[1-9][0-9]*$ ]] || { printf 'bad height: %q\n' "$h" >&2; exit 1; }

frame_bytes=$(( w * h * 3 ))

gif2rgb -1 -o "$tmpdir/all.rgb" "$gif"
total_bytes=$(wc -c <"$tmpdir/all.rgb")
(( total_bytes == frame_bytes )) || {
  printf 'gif2rgb -1 output %d bytes, expected exactly %d (one composed %dx%d frame)\n' \
    "$total_bytes" "$frame_bytes" "$w" "$h" >&2
  exit 1
}

# Output must contain at least one non-zero byte (some pixel rendered).
nonzero=$(python3 -c '
import sys
data = open(sys.argv[1], "rb").read()
print(sum(1 for b in data if b != 0))
' "$tmpdir/all.rgb")
(( nonzero > 0 )) || {
  printf 'gif2rgb output is all zeros\n' >&2
  exit 1
}
