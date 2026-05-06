#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-giftool-set-position-zero-zero
# @title: giftool -p 0,0 sets origin position
# @description: Runs giftool with -p 0,0 on the fire GIF and verifies the resulting GIF still parses with file(1) and gifbuild dump shows the position.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -p 0,0 <"$gif" >"$tmpdir/positioned.gif"
file "$tmpdir/positioned.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/positioned.gif" >"$tmpdir/dump.txt"
grep -E '^image left 0$' "$tmpdir/dump.txt" >/dev/null
grep -E '^image top 0$' "$tmpdir/dump.txt" >/dev/null
