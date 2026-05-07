#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giffix-treescap-noop-frame-count-preserved
# @title: giffix on a clean treescap.gif preserves frame count exactly
# @description: Runs giffix against a pristine treescap.gif (a non-interlaced fixture giffix supports) without any prior corruption and asserts giftool reports the same frame count for the giffix output as for the input, exercising giffix's pass-through behaviour on already-valid input.
# @timeout: 60
# @tags: usage, cli, giffix, passthrough
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giffix "$gif" >"$tmpdir/clean.gif"
file "$tmpdir/clean.gif" | grep -q 'GIF image data'

in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/clean.gif" | wc -l)
[[ "$in_n" -ge 1 ]]
[[ "$in_n" -eq "$out_n" ]] || {
    printf 'frame count drift in=%s out=%s\n' "$in_n" "$out_n" >&2
    exit 1
}
