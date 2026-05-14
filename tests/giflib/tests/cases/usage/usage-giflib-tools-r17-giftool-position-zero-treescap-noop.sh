#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-giftool-position-zero-treescap-noop
# @title: giftool -p 0,0 on treescap.gif preserves screen size and frame count
# @description: Pipes treescap.gif through giftool -p 0,0 to set image-block position to the origin, then asserts the screen-size string and per-frame count emitted by giftool -f match the input, exercising the position setter as an effective no-op for already-origin frames.
# @timeout: 60
# @tags: usage, cli, giftool, position
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 0,0 <"$gif" >"$tmpdir/p.gif"
file "$tmpdir/p.gif" | grep -q 'GIF image data'

in_s=$(giftool -f '%s\n' <"$gif" | sort -u)
out_s=$(giftool -f '%s\n' <"$tmpdir/p.gif" | sort -u)
[[ "$in_s" == "$out_s" ]] || {
    printf 'screen size differs in=%s out=%s\n' "$in_s" "$out_s" >&2
    exit 1
}

in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/p.gif" | wc -l)
[[ "$in_n" -eq "$out_n" ]] || {
    printf 'frame count differs in=%s out=%s\n' "$in_n" "$out_n" >&2
    exit 1
}
