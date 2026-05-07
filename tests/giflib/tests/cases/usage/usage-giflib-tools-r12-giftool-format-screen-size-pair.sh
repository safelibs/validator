#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-format-screen-size-pair
# @title: giftool -f %s emits the logical screen size as an x,y pair
# @description: Runs giftool -f '%s\n' on fire.gif and asserts every line matches the WxH pair (digit,digit) format and that all lines report the same screen size.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%s\n' <"$gif" >"$tmpdir/sizes.txt"

# Every row must look like W,H with non-zero positive integers.
if grep -vqE '^[1-9][0-9]*,[1-9][0-9]*$' "$tmpdir/sizes.txt"; then
    printf 'unexpected screen-size pair output:\n' >&2
    sed -n '1,10p' "$tmpdir/sizes.txt" >&2
    exit 1
fi

# All frames share the global screen descriptor, so the unique row count must be 1.
unique_count=$(sort -u "$tmpdir/sizes.txt" | wc -l)
[[ "$unique_count" -eq 1 ]]
