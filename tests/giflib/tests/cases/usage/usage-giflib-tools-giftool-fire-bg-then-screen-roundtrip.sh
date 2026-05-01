#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-fire-bg-then-screen-roundtrip
# @title: giftool -b followed by giftool -s preserves animation frame count
# @description: Sets the background index of fire.gif with giftool -b 5, then resizes the logical screen to 256,128 with a second giftool -s invocation, and verifies giftext reports BackGround = 5 with Width = 256, Height = 128 while gifbuild -d enumerates the same animation frame count as the source.
# @timeout: 60
# @tags: usage, cli, giftool, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

orig_frames=$(gifbuild -d "$gif" | grep -cE '^image # [0-9]+$' || true)
(( orig_frames >= 2 )) || {
  printf 'expected fire.gif to be multi-frame, got %d\n' "$orig_frames" >&2
  exit 1
}

giftool -b 5     <"$gif"               >"$tmpdir/bg.gif"
giftool -s 256,128 <"$tmpdir/bg.gif"   >"$tmpdir/final.gif"

file "$tmpdir/final.gif" | grep -q 'GIF image data'

giftext "$tmpdir/final.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 5'
validator_assert_contains "$tmpdir/info.txt" 'Width = 256, Height = 128'

new_frames=$(gifbuild -d "$tmpdir/final.gif" | grep -cE '^image # [0-9]+$' || true)
[[ "$new_frames" == "$orig_frames" ]] || {
  printf 'frame count drift: orig=%s final=%s\n' "$orig_frames" "$new_frames" >&2
  exit 1
}
