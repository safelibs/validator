#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-giftool-set-position-7-11-treescap
# @title: giftool -p 7,11 on treescap.gif sets image left=7 and top=11 in the gifbuild dump
# @description: Pipes treescap.gif through giftool -p 7,11 to set the image origin and runs gifbuild -d, asserting the dump contains both "image left 7" and "image top 11" lines, exercising the image-origin setter with non-symmetric coordinates distinct from prior 0,0 and 12,3 cases.
# @timeout: 60
# @tags: usage, cli, giftool, position, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 7,11 <"$gif" >"$tmpdir/positioned.gif"
file "$tmpdir/positioned.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/positioned.gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'image left 7'
validator_assert_contains "$tmpdir/dump.txt" 'image top 11'
