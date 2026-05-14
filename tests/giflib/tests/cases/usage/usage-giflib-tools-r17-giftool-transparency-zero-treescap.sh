#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-giftool-transparency-zero-treescap
# @title: giftool -t 0 treescap.gif sets transparent index 0 uniformly
# @description: Pipes treescap.gif through giftool -t 0 to assign transparent colour index 0 to every frame, reads back via giftool -f '%t\n', and asserts every reported transparent index is exactly 0, exercising the transparency setter path.
# @timeout: 60
# @tags: usage, cli, giftool, transparency
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -t 0 <"$gif" >"$tmpdir/t.gif"
file "$tmpdir/t.gif" | grep -q 'GIF image data'

giftool -f '%t\n' <"$tmpdir/t.gif" >"$tmpdir/t.txt"
[[ -s "$tmpdir/t.txt" ]]
unique=$(sort -u "$tmpdir/t.txt")
[[ "$unique" == "0" ]] || {
    printf 'expected uniform transparent index 0, got:\n%s\n' "$unique" >&2
    exit 1
}
