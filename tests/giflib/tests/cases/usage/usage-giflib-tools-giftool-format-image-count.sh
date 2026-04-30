#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-format-image-count
# @title: giftool -f counts animation frames
# @description: Uses giftool -f to emit one line per image in the multi-frame fire fixture and verifies the expected frame count.
# @timeout: 60
# @tags: usage, cli, giftool, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%n %wx%h\n' <"$gif" >"$tmpdir/frames.txt"
frames=$(wc -l <"$tmpdir/frames.txt")
[[ "$frames" -eq 33 ]]
grep -Fxq '1 30x60' "$tmpdir/frames.txt"
grep -Fxq '33 30x60' "$tmpdir/frames.txt"
