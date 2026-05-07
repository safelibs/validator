#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-format-image-index-monotonic
# @title: giftool -f %n emits a strictly increasing image index per frame
# @description: Runs giftool -f '%n\n' on fire.gif and confirms the resulting image-index column is monotonically increasing by exactly 1 each line, exercising the per-frame iteration counter.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%n\n' <"$gif" >"$tmpdir/n.txt"

# Each line must be a non-negative integer.
if grep -vqE '^[0-9]+$' "$tmpdir/n.txt"; then
    printf 'non-numeric output from giftool %%n:\n' >&2
    sed -n '1,10p' "$tmpdir/n.txt" >&2
    exit 1
fi

awk 'NR == 1 { prev = $1 - 1 }
     { if ($1 != prev + 1) { printf "non-monotonic at line %d: %s after %d\n", NR, $1, prev > "/dev/stderr"; exit 1 }
       prev = $1 }' "$tmpdir/n.txt"

frames=$(wc -l <"$tmpdir/n.txt")
[[ "$frames" -ge 2 ]]
