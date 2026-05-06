#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-giftool-format-width-fire-thirty
# @title: giftool -f %w reports image width 30 for every fire frame
# @description: Runs giftool -f '%w\n' on the multi-frame fire fixture and asserts every emitted line equals "30", confirming the per-frame image width matches the screen width across all animation frames.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%w\n' <"$gif" >"$tmpdir/widths.txt"

unique=$(sort -u "$tmpdir/widths.txt")
if [[ "$unique" != "30" ]]; then
    printf 'expected single width 30, got:\n' >&2
    sed -n '1,10p' "$tmpdir/widths.txt" >&2
    exit 1
fi

frames=$(wc -l <"$tmpdir/widths.txt")
[[ "$frames" -gt 1 ]]
