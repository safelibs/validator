#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-set-aspect-byte-roundtrip
# @title: giftool -a 64 sets the pixel aspect byte readable via %a
# @description: Runs giftool -a 64 on fire.gif to set the logical-screen pixel aspect byte to 64, then re-reads the value through giftool -f '%a\n' and confirms every frame now reports 64 instead of the original 0.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -a 64 <"$gif" >"$tmpdir/aspect.gif"
file "$tmpdir/aspect.gif" | grep -q 'GIF image data'

giftool -f '%a\n' <"$tmpdir/aspect.gif" >"$tmpdir/a.txt"
unique=$(sort -u "$tmpdir/a.txt")
if [[ "$unique" != "64" ]]; then
    printf 'expected uniform aspect byte 64, got:\n' >&2
    sed -n '1,10p' "$tmpdir/a.txt" >&2
    exit 1
fi
