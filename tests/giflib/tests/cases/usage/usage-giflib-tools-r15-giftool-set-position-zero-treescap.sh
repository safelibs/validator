#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giftool-set-position-zero-treescap
# @title: giftool -p 0,0 on treescap pins every frame to origin
# @description: Pipes treescap.gif through giftool -p 0,0, reads back via giftool -f '%p\n', and asserts every line equals "0,0", exercising the position setter at the origin on a non-interlaced fixture.
# @timeout: 60
# @tags: usage, cli, giftool, position
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 0,0 <"$gif" >"$tmpdir/origin.gif"
file "$tmpdir/origin.gif" | grep -q 'GIF image data'

giftool -f '%p\n' <"$tmpdir/origin.gif" >"$tmpdir/p.txt"
unique=$(sort -u "$tmpdir/p.txt")
if [[ "$unique" != "0,0" ]]; then
    printf 'expected uniform origin 0,0, got:\n%s\n' "$unique" >&2
    exit 1
fi
