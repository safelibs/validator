#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-set-bgcolor-index-roundtrip
# @title: giftool -b 7 sets the screen background color index
# @description: Applies giftool -b 7 to fire.gif to set the logical-screen background color index, then re-reads the field via giftool -f '%b\n' and confirms every frame reports 7.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -b 7 <"$gif" >"$tmpdir/bg.gif"
file "$tmpdir/bg.gif" | grep -q 'GIF image data'

giftool -f '%b\n' <"$tmpdir/bg.gif" >"$tmpdir/b.txt"
unique=$(sort -u "$tmpdir/b.txt")
if [[ "$unique" != "7" ]]; then
    printf 'expected uniform background index 7, got:\n' >&2
    sed -n '1,10p' "$tmpdir/b.txt" >&2
    exit 1
fi
