#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-interlace-delay-chain
# @title: giftool chains interlace then delay
# @description: Pipes treescap.gif through giftool -i 1 and then a second giftool -d 100 invocation, then verifies gifbuild reports both interlace and the delay 100 in the resulting GIF.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Stage 1: interlace.
giftool -i 1 <"$gif" >"$tmpdir/interlaced.gif"
file "$tmpdir/interlaced.gif" | grep -q 'GIF image data'

# Stage 2: add a 100 cs delay on the already interlaced stream.
giftool -d 100 <"$tmpdir/interlaced.gif" >"$tmpdir/final.gif"
file "$tmpdir/final.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/final.gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'delay 100'

giftext "$tmpdir/final.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Image is Interlaced'
