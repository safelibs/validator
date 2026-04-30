#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-middle-frame
# @title: gif2rgb planar decode of fire animation produces distinct R and B channels
# @description: Decodes fire.gif using gif2rgb -o (planar RGB output) and confirms the resulting per-channel R, G, and B files each have width*height bytes, contain at least one non-zero byte, and that the R channel differs from the B channel for the rendered fire palette.
# @timeout: 60
# @tags: usage, cli, gif2rgb, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%n %wx%h\n' <"$gif" >"$tmpdir/frames.txt"
w=$(awk 'NR==1 {split($2, a, "x"); print a[1]; exit}' "$tmpdir/frames.txt")
h=$(awk 'NR==1 {split($2, a, "x"); print a[2]; exit}' "$tmpdir/frames.txt")
[[ "$w" =~ ^[1-9][0-9]*$ ]] || { printf 'bad width: %q\n' "$w" >&2; exit 1; }
[[ "$h" =~ ^[1-9][0-9]*$ ]] || { printf 'bad height: %q\n' "$h" >&2; exit 1; }

plane_bytes=$(( w * h ))

gif2rgb -o "$tmpdir/fire" "$gif"

for ch in R G B; do
  validator_require_file "$tmpdir/fire.$ch"
  got=$(wc -c <"$tmpdir/fire.$ch")
  (( got == plane_bytes )) || {
    printf 'channel %s file has %d bytes, expected %d (%dx%d)\n' "$ch" "$got" "$plane_bytes" "$w" "$h" >&2
    exit 1
  }
  nonzero=$(python3 -c '
import sys
data = open(sys.argv[1], "rb").read()
print(sum(1 for b in data if b != 0))
' "$tmpdir/fire.$ch")
  (( nonzero > 0 )) || { printf 'channel %s plane is all zeros\n' "$ch" >&2; exit 1; }
done

# Fire palette is warm-toned: red plane should differ from blue plane.
if cmp -s "$tmpdir/fire.R" "$tmpdir/fire.B"; then
  printf 'R and B channels are byte-identical for fire.gif; expected color variation\n' >&2
  exit 1
fi
