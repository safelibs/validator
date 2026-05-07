#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-giftool-set-delay-25-fire
# @title: giftool -d 25 forces every fire frame to a 25 cs delay
# @description: Pipes fire.gif through giftool -d 25 then reads back per-frame delays via giftool -f '%d\n' and asserts every line equals 25, exercising the global delay setter.
# @timeout: 60
# @tags: usage, cli, giftool, delay
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -d 25 <"$gif" >"$tmpdir/d.gif"
file "$tmpdir/d.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/d.gif" >"$tmpdir/d.txt"
unique=$(sort -u "$tmpdir/d.txt")
if [[ "$unique" != "25" ]]; then
    printf 'expected uniform delay 25, got:\n%s\n' "$unique" >&2
    exit 1
fi
