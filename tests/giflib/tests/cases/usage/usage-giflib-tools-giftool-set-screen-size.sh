#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-set-screen-size
# @title: giftool -s rewrites logical screen size
# @description: Resizes the logical screen descriptor with giftool -s and verifies giftext reports the new width and height.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -s 80,60 <"$gif" >"$tmpdir/resized.gif"
file "$tmpdir/resized.gif" | grep -q 'GIF image data'

giftext "$tmpdir/resized.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Width = 80, Height = 60'
