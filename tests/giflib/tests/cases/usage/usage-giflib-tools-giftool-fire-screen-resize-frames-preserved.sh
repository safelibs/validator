#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-fire-screen-resize-frames-preserved
# @title: giftool -s on fire.gif rewrites screen size while preserving frame count
# @description: Resizes the logical screen of the multi-frame fire.gif to 320x240 with giftool -s, verifies giftext reports the new screen size and that the frame count emitted by gifbuild -d matches the original animation frame count, ensuring -s rewrites only the screen descriptor.
# @timeout: 60
# @tags: usage, cli, giftool, animation, screen
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Count frames in the original animation as the invariant we expect to preserve.
gifbuild -d "$gif" >"$tmpdir/orig-dump.txt"
orig_frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/orig-dump.txt" || true)
(( orig_frames >= 2 )) || {
  printf 'expected fire.gif to be multi-frame, got %d\n' "$orig_frames" >&2
  exit 1
}

new_w=320
new_h=240
giftool -s "$new_w","$new_h" <"$gif" >"$tmpdir/resized.gif"
file "$tmpdir/resized.gif" | grep -q 'GIF image data'

giftext "$tmpdir/resized.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" "Width = $new_w, Height = $new_h"

gifbuild -d "$tmpdir/resized.gif" >"$tmpdir/resized-dump.txt"
new_frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/resized-dump.txt" || true)
if [[ "$new_frames" != "$orig_frames" ]]; then
  printf 'frame count changed by giftool -s: %s -> %s\n' "$orig_frames" "$new_frames" >&2
  exit 1
fi
