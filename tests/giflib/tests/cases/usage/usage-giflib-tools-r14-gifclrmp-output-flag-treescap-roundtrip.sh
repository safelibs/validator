#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-gifclrmp-output-flag-treescap-roundtrip
# @title: gifclrmp dump-then-reload preserves treescap palette row count and frame count
# @description: Dumps treescap.gif's palette via gifclrmp -s, reloads the same palette via gifclrmp -l, and asserts the post-mapping GIF dump has the same number of palette rows AND that the frame count reported by giftool -f '%n\n' is unchanged from the input fixture, exercising the colormap-translation pipeline.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/cmap.txt"
[[ -s "$tmpdir/cmap.txt" ]]
in_rows=$(wc -l <"$tmpdir/cmap.txt")

gifclrmp -l "$tmpdir/cmap.txt" "$gif" >"$tmpdir/out.gif"
file "$tmpdir/out.gif" | grep -q 'GIF image data'

gifclrmp -s "$tmpdir/out.gif" >"$tmpdir/out-cmap.txt"
out_rows=$(wc -l <"$tmpdir/out-cmap.txt")
[[ "$in_rows" -eq "$out_rows" ]] || {
    printf 'palette row count drift in=%s out=%s\n' "$in_rows" "$out_rows" >&2
    exit 1
}

in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/out.gif" | wc -l)
[[ "$in_n" -eq "$out_n" ]]
