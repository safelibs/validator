#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-giftool-set-background-12-treescap
# @title: giftool -b 12 on treescap.gif yields giftext "BackGround = 12"
# @description: Pipes treescap.gif through giftool -b 12 to set the background colour index and runs giftext on the result, asserting the giftext output contains the literal "BackGround = 12" line, exercising the background-index setter with the value 12 (distinct from prior 0, 5, 7, and 9 cases) read through giftext rather than gifbuild dump.
# @timeout: 60
# @tags: usage, cli, giftool, background, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 12 <"$gif" >"$tmpdir/bg.gif"
file "$tmpdir/bg.gif" | grep -q 'GIF image data'

giftext "$tmpdir/bg.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 12'
