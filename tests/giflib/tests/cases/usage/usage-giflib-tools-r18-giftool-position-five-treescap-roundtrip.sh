#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-giftool-position-five-treescap-roundtrip
# @title: giftool -p 5,5 on treescap.gif emits a valid GIF and preserves frame count
# @description: Pipes treescap.gif through giftool -p 5,5 to set image-block position to (5,5), then asserts the result is recognised as a GIF stream by file and that giftool -f '%n\n' frame-count matches the input, exercising the position setter at a non-origin coordinate.
# @timeout: 60
# @tags: usage, cli, giftool, position, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 5,5 <"$gif" >"$tmpdir/p.gif"
file "$tmpdir/p.gif" | grep -q 'GIF image data'

in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/p.gif" | wc -l)
[[ "$in_n" -eq "$out_n" ]] || {
    printf 'frame count differs in=%s out=%s\n' "$in_n" "$out_n" >&2
    exit 1
}
