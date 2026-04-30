#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-enable-interlace
# @title: giftool -i marks images interlaced
# @description: Sets the interlace flag on a non-interlaced fixture via giftool -i and confirms giftext reports the image as interlaced.
# @timeout: 60
# @tags: usage, cli, giftool, interlace
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Confirm the source fixture is not interlaced before we toggle the flag.
giftext "$gif" >"$tmpdir/before.txt"
if grep -q 'Image is Interlaced' "$tmpdir/before.txt"; then
  echo 'fixture unexpectedly already interlaced' >&2
  exit 1
fi

giftool -i 1 <"$gif" >"$tmpdir/interlaced.gif"
giftext "$tmpdir/interlaced.gif" >"$tmpdir/after.txt"
validator_assert_contains "$tmpdir/after.txt" 'Image is Interlaced'
