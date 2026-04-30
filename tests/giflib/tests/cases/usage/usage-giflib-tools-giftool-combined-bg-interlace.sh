#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-combined-bg-interlace
# @title: giftool combines -b and -i in one pass
# @description: Invokes giftool with both -b for the screen background index and -i to set the interlace flag on the same input and verifies giftext records both transformations on the resulting GIF.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Source fixture must not already be interlaced; otherwise the -i 1 assertion
# would be vacuous.
giftext "$gif" >"$tmpdir/before.txt"
if grep -q 'Image is Interlaced' "$tmpdir/before.txt"; then
  printf 'fixture unexpectedly already interlaced\n' >&2
  exit 1
fi

giftool -b 4 -i 1 <"$gif" >"$tmpdir/combined.gif"
file "$tmpdir/combined.gif" | grep -q 'GIF image data'

giftext "$tmpdir/combined.gif" >"$tmpdir/after.txt"
validator_assert_contains "$tmpdir/after.txt" 'BackGround = 4'
validator_assert_contains "$tmpdir/after.txt" 'Image is Interlaced'
