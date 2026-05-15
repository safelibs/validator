#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-giftool-set-delay-30-fire-uniform
# @title: giftool -d 30 on fire.gif sets every frame delay to 30 via giftool -f '%d'
# @description: Pipes fire.gif through giftool -d 30 to set the frame-delay field to 30 centiseconds, reads back via giftool -f '%d\n' and asserts every line equals "30", exercising the per-frame uniform delay setter on the multi-frame fire fixture with a distinctive value not previously asserted (existing tests cover 5, 10, 15, 25, 50).
# @timeout: 60
# @tags: usage, cli, giftool, delay, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -d 30 <"$gif" >"$tmpdir/d.gif"
file "$tmpdir/d.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/d.gif" >"$tmpdir/d.txt"
[[ -s "$tmpdir/d.txt" ]]
unique=$(sort -u "$tmpdir/d.txt")
[[ "$unique" == "30" ]] || {
    printf 'expected uniform delay 30, got:\n%s\n' "$unique" >&2
    exit 1
}
