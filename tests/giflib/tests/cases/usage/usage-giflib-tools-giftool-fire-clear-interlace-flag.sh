#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-fire-clear-interlace-flag
# @title: giftool -i 0 clears the interlace flag on every fire.gif frame
# @description: Confirms the multi-frame fire.gif fixture has its Image is Interlaced flag set on every frame, runs giftool -i 0 on it, and asserts every interlace marker is gone from the result while the screen size and frame count are preserved -- complementing the existing single-frame treescap-interlaced clear-flag coverage with a multi-frame case.
# @timeout: 60
# @tags: usage, cli, giftool, interlace
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/before.txt"
before_frames=$(grep -cE '^Image #[0-9]+:' "$tmpdir/before.txt" || true)
before_interlaced=$(grep -cE 'Image is Interlaced' "$tmpdir/before.txt" || true)

if (( before_frames < 2 )); then
  printf 'expected fire.gif to be multi-frame, got %s\n' "$before_frames" >&2
  exit 1
fi
if [[ "$before_interlaced" != "$before_frames" ]]; then
  printf 'fire.gif baseline expected interlaced on every frame: frames=%s interlaced=%s\n' \
    "$before_frames" "$before_interlaced" >&2
  exit 1
fi

orig_screen=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/before.txt" | head -n 1)
[[ -n "$orig_screen" ]] || { printf 'missing screen size on source\n' >&2; exit 1; }

giftool -i 0 <"$gif" >"$tmpdir/cleared.gif"
file "$tmpdir/cleared.gif" | grep -q 'GIF image data'

giftext "$tmpdir/cleared.gif" >"$tmpdir/after.txt"
after_frames=$(grep -cE '^Image #[0-9]+:' "$tmpdir/after.txt" || true)
after_interlaced=$(grep -cE 'Image is Interlaced' "$tmpdir/after.txt" || true)

if [[ "$after_frames" != "$before_frames" ]]; then
  printf 'frame count drift: before=%s after=%s\n' "$before_frames" "$after_frames" >&2
  exit 1
fi

if (( after_interlaced != 0 )); then
  printf 'expected zero interlace markers after -i 0, got %s\n' "$after_interlaced" >&2
  grep 'Image is Interlaced' "$tmpdir/after.txt" >&2 || true
  exit 1
fi

new_screen=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/after.txt" | head -n 1)
if [[ "$orig_screen" != "$new_screen" ]]; then
  printf 'screen size changed: orig=%q new=%q\n' "$orig_screen" "$new_screen" >&2
  exit 1
fi
