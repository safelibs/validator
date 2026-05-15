#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-giftool-background-five-treescap-giftext
# @title: giftool -b 5 on treescap.gif updates the BackGround value reported by giftext
# @description: Pipes treescap.gif through giftool -b 5 to set the screen background colour index to 5, then asserts giftext on the result emits a line containing the literal substring "BackGround = 5", exercising the background index setter as seen through the textual report.
# @timeout: 60
# @tags: usage, cli, giftool, background, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 5 <"$gif" >"$tmpdir/bg.gif"
file "$tmpdir/bg.gif" | grep -q 'GIF image data'

giftext "$tmpdir/bg.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 5'
