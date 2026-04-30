#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-fire-bg-position-chain
# @title: giftool chains -b then -p across the fire animation
# @description: Pipes the multi-frame fire.gif through giftool -b 7 to set the screen background index, then through a second giftool -p 0,0 invocation, and verifies giftext reports BackGround = 7 while gifbuild dumps every animated frame with image left 0 and image top 0, demonstrating that a -b transform survives a follow-up -p pass on an animated stream.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Capture the original frame count as the invariant we expect to preserve.
gifbuild -d "$gif" >"$tmpdir/orig-dump.txt"
orig_frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/orig-dump.txt" || true)
(( orig_frames >= 2 )) || {
  printf 'expected fire.gif to be multi-frame, got %d\n' "$orig_frames" >&2
  exit 1
}

# Stage 1: rewrite the screen background index.
giftool -b 7 <"$gif" >"$tmpdir/bg.gif"
file "$tmpdir/bg.gif" | grep -q 'GIF image data'

# Stage 2: anchor every image origin to (0,0).
giftool -p 0,0 <"$tmpdir/bg.gif" >"$tmpdir/final.gif"
file "$tmpdir/final.gif" | grep -q 'GIF image data'

# The screen-level -b result must still be visible after the per-image -p pass.
giftext "$tmpdir/final.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 7'

# Frame count must not have changed, and every image descriptor must read 0,0.
gifbuild -d "$tmpdir/final.gif" >"$tmpdir/final-dump.txt"
new_frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/final-dump.txt" || true)
[[ "$new_frames" == "$orig_frames" ]] || {
  printf 'frame count changed across pipeline: %s -> %s\n' "$orig_frames" "$new_frames" >&2
  exit 1
}

left_zero=$(grep -cE '^[[:space:]]*image left 0$' "$tmpdir/final-dump.txt" || true)
top_zero=$(grep -cE '^[[:space:]]*image top 0$' "$tmpdir/final-dump.txt" || true)
if (( left_zero < orig_frames )) || (( top_zero < orig_frames )); then
  printf 'expected %d image left/top 0 lines, got left=%d top=%d\n' \
    "$orig_frames" "$left_zero" "$top_zero" >&2
  sed -n '1,40p' "$tmpdir/final-dump.txt" >&2
  exit 1
fi

# A non-zero offset must not survive the reset.
if grep -Eq '^[[:space:]]*image left [1-9][0-9]*$|^[[:space:]]*image top [1-9][0-9]*$' \
      "$tmpdir/final-dump.txt"; then
  printf 'unexpected non-zero image origin after -p 0,0\n' >&2
  exit 1
fi
