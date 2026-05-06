#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-giftool-set-background-seven-treescap
# @title: giftool -b 7 rewrites the screen background index on treescap
# @description: Pipes treescap through giftool -b 7 and verifies the resulting GIF reports "screen background 7" in gifbuild -d output, exercising the background-index header rewriter.
# @timeout: 60
# @tags: usage, cli, giftool, background
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 7 <"$gif" >"$tmpdir/out.gif"
gifbuild -d "$tmpdir/out.gif" >"$tmpdir/dump.txt"

validator_assert_contains "$tmpdir/dump.txt" 'screen background 7'
