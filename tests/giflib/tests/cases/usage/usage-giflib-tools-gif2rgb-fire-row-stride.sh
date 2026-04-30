#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-row-stride
# @title: gif2rgb fire RGB output is a multiple of width*3
# @description: Decodes the multi-frame fire.gif into a packed RGB stream with gif2rgb -1, reads the logical screen width from giftext, and asserts the produced RGB byte count is an exact multiple of width*3 so every emitted scanline is fully populated.
# @timeout: 60
# @tags: usage, cli, gif2rgb, geometry
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
width=$(grep -Eo 'Width = [0-9]+' "$tmpdir/info.txt" | head -n1 | grep -Eo '[0-9]+')
[[ -n "$width" ]] || { printf 'no Width field in giftext output\n' >&2; exit 1; }
(( width > 0 ))

gif2rgb -1 -o "$tmpdir/fire.rgb" "$gif"
rgb_bytes=$(wc -c <"$tmpdir/fire.rgb")
(( rgb_bytes > 0 ))

stride=$(( width * 3 ))
if (( rgb_bytes % stride != 0 )); then
  printf 'gif2rgb output %d bytes is not a multiple of width*3=%d\n' "$rgb_bytes" "$stride" >&2
  exit 1
fi
