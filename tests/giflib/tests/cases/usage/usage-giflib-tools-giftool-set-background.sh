#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-set-background
# @title: giftool -b updates background color index
# @description: Rewrites the logical screen background color index with giftool -b and verifies the new index appears in giftext output.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 9 <"$gif" >"$tmpdir/bg.gif"
giftext "$tmpdir/bg.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 9'
