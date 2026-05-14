#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-giftool-delay-ten-fire-uniform
# @title: giftool -d 10 on fire.gif emits uniform delay across all frames
# @description: Pipes fire.gif through giftool -d 10 to set every frame delay-time to 10 centiseconds, then reads back via giftool -f '%d\n' and asserts every line equals "10", exercising the per-frame delay setter on a multi-frame animation fixture distinct from prior single-value tests.
# @timeout: 60
# @tags: usage, cli, giftool, delay, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -d 10 <"$gif" >"$tmpdir/d.gif"
file "$tmpdir/d.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/d.gif" >"$tmpdir/d.txt"
[[ -s "$tmpdir/d.txt" ]]
unique=$(sort -u "$tmpdir/d.txt")
[[ "$unique" == "10" ]] || {
    printf 'expected uniform delay 10, got:\n%s\n' "$unique" >&2
    exit 1
}
