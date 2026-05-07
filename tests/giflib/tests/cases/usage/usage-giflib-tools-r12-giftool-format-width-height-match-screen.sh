#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-format-width-height-match-screen
# @title: giftool -f %wx%h yields per-frame dimensions bounded by the screen size
# @description: Runs giftool -f '%w %h\n' on fire.gif and asserts each per-frame width and height is positive and not greater than the screen-descriptor width/height parsed via giftool -f '%s\n'.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%s\n' <"$gif" >"$tmpdir/screen.txt"
giftool -f '%w %h\n' <"$gif" >"$tmpdir/dims.txt"

# Take any single screen-size line (they are all identical).
read -r screen_w screen_h <<<"$(head -n 1 "$tmpdir/screen.txt" | tr ',' ' ')"
[[ "$screen_w" -gt 0 && "$screen_h" -gt 0 ]]

awk -v sw="$screen_w" -v sh="$screen_h" '
  { if (NF != 2) exit 1
    if ($1 + 0 <= 0 || $2 + 0 <= 0) exit 1
    if ($1 + 0 > sw || $2 + 0 > sh) exit 1 }
' "$tmpdir/dims.txt"

frames=$(wc -l <"$tmpdir/dims.txt")
[[ "$frames" -ge 1 ]]
