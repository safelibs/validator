#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-background-zero-dump
# @title: giftool -b 0 lands as screen background 0
# @description: Forces the screen background index to 0 with giftool -b on treescap.gif and confirms gifbuild -d reports screen background 0 in its textual dump.
# @timeout: 60
# @tags: usage, cli, giftool, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 0 <"$gif" >"$tmpdir/bg0.gif"
file "$tmpdir/bg0.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/bg0.gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'screen background 0'

# Cross-check via giftext.
giftext "$tmpdir/bg0.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 0'
