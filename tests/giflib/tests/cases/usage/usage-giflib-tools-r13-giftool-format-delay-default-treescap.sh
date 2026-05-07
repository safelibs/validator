#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-giftool-format-delay-default-treescap
# @title: giftool -f %d emits a non-negative integer delay for treescap frames
# @description: Runs giftool -f '%d\n' on treescap.gif and asserts every line is a non-negative integer parseable as a hundredth-of-a-second delay value.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -f '%d\n' <"$gif" >"$tmpdir/d.txt"

[[ -s "$tmpdir/d.txt" ]]
if grep -vqE '^[0-9]+$' "$tmpdir/d.txt"; then
    printf 'non-numeric delay output:\n' >&2
    sed -n '1,10p' "$tmpdir/d.txt" >&2
    exit 1
fi
