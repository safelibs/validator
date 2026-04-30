#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-set-delay
# @title: giftool -d sets graphics control delay
# @description: Applies a giftool -d delay value and confirms gifbuild dumps the requested delay in the graphics control extension.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -d 25 <"$gif" >"$tmpdir/delayed.gif"
file "$tmpdir/delayed.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/delayed.gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'delay 25'
