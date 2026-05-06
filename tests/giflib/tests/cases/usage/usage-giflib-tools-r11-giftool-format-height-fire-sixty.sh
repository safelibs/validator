#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-giftool-format-height-fire-sixty
# @title: giftool -f %h reports image height 60 for every fire frame
# @description: Runs giftool -f '%h\n' on the multi-frame fire fixture and asserts every emitted line equals "60", confirming the per-frame image height matches the screen height across all animation frames.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%h\n' <"$gif" >"$tmpdir/heights.txt"

unique=$(sort -u "$tmpdir/heights.txt")
if [[ "$unique" != "60" ]]; then
    printf 'expected single height 60, got:\n' >&2
    sed -n '1,10p' "$tmpdir/heights.txt" >&2
    exit 1
fi

frames=$(wc -l <"$tmpdir/heights.txt")
[[ "$frames" -gt 1 ]]
