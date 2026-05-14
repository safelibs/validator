#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-giftool-background-zero-treescap-roundtrip
# @title: giftool -b 0 on treescap.gif emits a valid GIF with preserved screen size
# @description: Pipes treescap.gif through giftool -b 0 to set the background color index to 0, then asserts the result is a valid GIF stream whose unique giftool -f '%s\n' screen-size string matches the input, exercising the background-index setter without changing screen geometry.
# @timeout: 60
# @tags: usage, cli, giftool, background, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 0 <"$gif" >"$tmpdir/bg.gif"
file "$tmpdir/bg.gif" | grep -q 'GIF image data'

in_s=$(giftool -f '%s\n' <"$gif" | sort -u)
out_s=$(giftool -f '%s\n' <"$tmpdir/bg.gif" | sort -u)
[[ "$in_s" == "$out_s" ]] || {
    printf 'screen size differs in=%s out=%s\n' "$in_s" "$out_s" >&2
    exit 1
}
