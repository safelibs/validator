#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-giftool-set-screen-200x100
# @title: giftool -s 200,100 sets logical screen size
# @description: Applies giftool -s 200,100 to fire.gif and verifies gifbuild dump reports "screen width 200" and "screen height 100".
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -s 200,100 <"$gif" >"$tmpdir/resized.gif"
file "$tmpdir/resized.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/resized.gif" >"$tmpdir/dump.txt"
grep -E '^screen width 200$' "$tmpdir/dump.txt" >/dev/null
grep -E '^screen height 100$' "$tmpdir/dump.txt" >/dev/null
