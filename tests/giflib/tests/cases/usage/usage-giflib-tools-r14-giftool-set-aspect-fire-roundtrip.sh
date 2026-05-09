#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftool-set-aspect-fire-roundtrip
# @title: giftool -b sets background color index readable via -f %b
# @description: Pipes fire.gif through giftool -b 5 to overwrite the logical screen descriptor's background color index, then reads it back via giftool -f '%b\n' and asserts every emitted line reports 5, exercising a screen-descriptor mutation round-trip. (giftool's -a aspect flag prints "unknown operation mode" on giflib 5.2.2; the -b background index path is the documented mutation surface.)
# @timeout: 60
# @tags: usage, cli, giftool, aspect
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -b 5 <"$gif" >"$tmpdir/bg.gif"
file "$tmpdir/bg.gif" | grep -q 'GIF image data'

giftool -f '%b\n' <"$tmpdir/bg.gif" >"$tmpdir/b.txt"
[[ -s "$tmpdir/b.txt" ]]
unique=$(sort -u "$tmpdir/b.txt")
if [[ "$unique" != "5" ]]; then
    printf 'expected uniform background 5, got:\n%s\n' "$unique" >&2
    exit 1
fi
