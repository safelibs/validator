#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-bg-delay-disposal-chain
# @title: giftool -b 7 -d 30 -x 2 chains background, delay and disposal in one invocation
# @description: Pipes fire.gif through a single giftool invocation that simultaneously sets the screen background index (-b 7), the per-frame delay (-d 30), and the per-frame disposal mode (-x 2), then asserts giftext shows BackGround = 7, every DelayTime line equals 30, and every Disposal Mode line equals 2 with both per-frame counts matching the frame count.
# @timeout: 60
# @tags: usage, cli, giftool, chain
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -b 7 -d 30 -x 2 <"$gif" >"$tmpdir/chained.gif"
file "$tmpdir/chained.gif" | grep -q 'GIF image data'

giftext   "$tmpdir/chained.gif" >"$tmpdir/info.txt"
giftext -e "$tmpdir/chained.gif" >"$tmpdir/ext.txt"

frame_count=$(grep -cE '^Image #[0-9]+:' "$tmpdir/info.txt" || true)
if (( frame_count < 2 )); then
  printf 'expected multi-frame fire.gif, got %s\n' "$frame_count" >&2
  exit 1
fi

# Background index in the screen header.
if ! grep -qE 'BackGround = 7,' "$tmpdir/info.txt"; then
  printf 'expected BackGround = 7 in giftext output\n' >&2
  grep -E 'BackGround' "$tmpdir/info.txt" >&2 || true
  exit 1
fi

delay30=$(grep -cE 'DelayTime: 30$' "$tmpdir/ext.txt" || true)
disposal2=$(grep -cE 'Disposal Mode: 2$' "$tmpdir/ext.txt" || true)

if [[ "$delay30" != "$frame_count" ]]; then
  printf 'expected DelayTime: 30 on every frame: frames=%s delay30=%s\n' \
    "$frame_count" "$delay30" >&2
  grep -E 'DelayTime' "$tmpdir/ext.txt" >&2 || true
  exit 1
fi
if [[ "$disposal2" != "$frame_count" ]]; then
  printf 'expected Disposal Mode: 2 on every frame: frames=%s disposal2=%s\n' \
    "$frame_count" "$disposal2" >&2
  grep -E 'Disposal Mode' "$tmpdir/ext.txt" >&2 || true
  exit 1
fi
