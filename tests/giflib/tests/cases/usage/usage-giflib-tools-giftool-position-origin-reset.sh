#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-position-origin-reset
# @title: giftool -p 0,0 anchors the image to the origin
# @description: First moves an image origin to a non-zero position with giftool -p 5,7, pipes that result through giftool -p 0,0 to reset, and verifies the final gifbuild dump shows image left 0 and image top 0 with no remnant of the intermediate offset.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 5,7 <"$gif" >"$tmpdir/shifted.gif"
gifbuild -d "$tmpdir/shifted.gif" >"$tmpdir/shifted-dump.txt"
validator_assert_contains "$tmpdir/shifted-dump.txt" 'image left 5'
validator_assert_contains "$tmpdir/shifted-dump.txt" 'image top 7'

giftool -p 0,0 <"$tmpdir/shifted.gif" >"$tmpdir/origin.gif"
gifbuild -d "$tmpdir/origin.gif" >"$tmpdir/origin-dump.txt"
validator_assert_contains "$tmpdir/origin-dump.txt" 'image left 0'
validator_assert_contains "$tmpdir/origin-dump.txt" 'image top 0'

# The reset dump must not contain the prior 5/7 offsets on any image descriptor.
if grep -Eq '^image left 5$|^image top 7$' "$tmpdir/origin-dump.txt"; then
  printf 'origin reset failed; intermediate offset still present\n' >&2
  sed -n '1,80p' "$tmpdir/origin-dump.txt" >&2
  exit 1
fi
