#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-giftool-delay-five-treescap-uniform
# @title: giftool -d 5 treescap.gif emits uniform delay across all frames
# @description: Pipes treescap.gif through giftool -d 5 to set every frame delay-time to 5 centiseconds, then reads back via giftool -f '%d\n' and asserts every line equals "5", exercising the per-frame delay setter at a value distinct from prior batches.
# @timeout: 60
# @tags: usage, cli, giftool, delay
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -d 5 <"$gif" >"$tmpdir/d.gif"
file "$tmpdir/d.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/d.gif" >"$tmpdir/d.txt"
[[ -s "$tmpdir/d.txt" ]]
unique=$(sort -u "$tmpdir/d.txt")
[[ "$unique" == "5" ]] || {
    printf 'expected uniform delay 5, got:\n%s\n' "$unique" >&2
    exit 1
}
