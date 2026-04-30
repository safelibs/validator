#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-set-position
# @title: giftool -p sets image origin
# @description: Moves the image descriptor origin with giftool -p and confirms gifbuild dumps the requested left and top coordinates.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 3,4 <"$gif" >"$tmpdir/positioned.gif"
gifbuild -d "$tmpdir/positioned.gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'image left 3'
validator_assert_contains "$tmpdir/dump.txt" 'image top 4'
