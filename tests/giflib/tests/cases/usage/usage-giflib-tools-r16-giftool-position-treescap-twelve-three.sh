#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-giftool-position-treescap-twelve-three
# @title: giftool -p 12,3 treescap.gif round-trips through giftool -f '%p\n'
# @description: Pipes treescap.gif (non-interlaced) through giftool -p 12,3 to set per-frame image-left/top, then reads back via giftool -f '%p\n' and asserts every line equals "12,3", exercising the position setter at a non-origin offset distinct from existing 0,0/5,7/6,9 cases.
# @timeout: 60
# @tags: usage, cli, giftool, position
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 12,3 <"$gif" >"$tmpdir/p.gif"
file "$tmpdir/p.gif" | grep -q 'GIF image data'

giftool -f '%p\n' <"$tmpdir/p.gif" >"$tmpdir/p.txt"
[[ -s "$tmpdir/p.txt" ]]
unique=$(sort -u "$tmpdir/p.txt")
[[ "$unique" == "12,3" ]] || {
    printf 'expected uniform position 12,3, got:\n%s\n' "$unique" >&2
    exit 1
}
