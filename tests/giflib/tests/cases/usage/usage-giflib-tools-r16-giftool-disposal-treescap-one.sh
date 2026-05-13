#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-giftool-disposal-treescap-one
# @title: giftool -x 1 treescap.gif sets disposal mode "do-not-dispose" on every frame
# @description: Pipes treescap.gif (non-interlaced) through giftool -x 1 to set disposal mode 1 (do-not-dispose) on every frame, then reads back via giftool -f '%x\n' and asserts every line equals "1", exercising the disposal setter at value 1 complementing existing 0/2/3 cases.
# @timeout: 60
# @tags: usage, cli, giftool, disposal
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -x 1 <"$gif" >"$tmpdir/x.gif"
file "$tmpdir/x.gif" | grep -q 'GIF image data'

giftool -f '%x\n' <"$tmpdir/x.gif" >"$tmpdir/x.txt"
[[ -s "$tmpdir/x.txt" ]]
unique=$(sort -u "$tmpdir/x.txt")
[[ "$unique" == "1" ]] || {
    printf 'expected uniform disposal 1, got:\n%s\n' "$unique" >&2
    exit 1
}
