#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-giftool-interlace-off-fire-roundtrip
# @title: giftool -i 0 on fire.gif preserves GIF magic and frame count
# @description: Pipes fire.gif through giftool -i 0 to turn the interlace flag off and asserts the result is a valid GIF stream whose per-frame count emitted by giftool -f '%n\n' equals the input frame count, exercising the interlace clear operation on a multi-frame fixture.
# @timeout: 60
# @tags: usage, cli, giftool, interlace, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -i 0 <"$gif" >"$tmpdir/off.gif"
file "$tmpdir/off.gif" | grep -q 'GIF image data'

in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/off.gif" | wc -l)
[[ "$in_n" -eq "$out_n" ]] || {
    printf 'frame count differs in=%s out=%s\n' "$in_n" "$out_n" >&2
    exit 1
}
