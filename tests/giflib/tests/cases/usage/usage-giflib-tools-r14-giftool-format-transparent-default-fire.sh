#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftool-format-transparent-default-fire
# @title: giftool -f compound cookie line emits per-frame width, height, position for fire.gif
# @description: Runs giftool -f '%w %h %p\n' against fire.gif and asserts each line matches the "W H X,Y" compound shape with positive integers for W/H and a comma-separated coordinate pair for the position cookie, exercising compound directive parsing.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%w %h %p\n' <"$gif" >"$tmpdir/whp.txt"

[[ -s "$tmpdir/whp.txt" ]]

# Each row must look like "W H X,Y" with non-negative integers.
if grep -vqE '^[1-9][0-9]* [1-9][0-9]* [0-9]+,[0-9]+$' "$tmpdir/whp.txt"; then
    printf 'unexpected row format:\n' >&2
    sed -n '1,10p' "$tmpdir/whp.txt" >&2
    exit 1
fi

frames=$(wc -l <"$tmpdir/whp.txt")
[[ "$frames" -ge 2 ]]
