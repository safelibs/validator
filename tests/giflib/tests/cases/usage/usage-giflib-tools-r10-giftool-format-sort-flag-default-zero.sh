#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-format-sort-flag-default-zero
# @title: giftool -f %z prints zero color-table sort flag for fire.gif
# @description: Runs giftool -f '%z\n' against the fire.gif fixture and confirms the per-image color-table sort flag is uniformly 0, exercising the %z format directive against an unsorted-palette source.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%z\n' <"$gif" >"$tmpdir/sort.txt"

unique=$(sort -u "$tmpdir/sort.txt")
if [[ "$unique" != "0" ]]; then
    printf 'expected sort flag 0, got distinct values:\n' >&2
    sed -n '1,10p' "$tmpdir/sort.txt" >&2
    exit 1
fi

frames=$(wc -l <"$tmpdir/sort.txt")
[[ "$frames" -ge 5 ]]
