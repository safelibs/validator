#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-giftool-set-screen-size-50x50-format
# @title: giftool -s 50,50 on treescap.gif followed by gifbuild dump shows "screen width 50"
# @description: Pipes treescap.gif through giftool -s 50,50 to set the logical screen size and then runs gifbuild -d on the result, asserting the dump contains both literal lines "screen width 50" and "screen height 50", exercising the screen-size setter through the gifbuild dump distinct from prior 200x100, 20x20, and other screen-size cases.
# @timeout: 60
# @tags: usage, cli, giftool, screen-size, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -s 50,50 <"$gif" >"$tmpdir/sized.gif"
file "$tmpdir/sized.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/sized.gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'screen width 50'
validator_assert_contains "$tmpdir/dump.txt" 'screen height 50'
