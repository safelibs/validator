#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-position-then-bg-chain
# @title: giftool -p then -b chained over two passes preserves both transforms
# @description: Pipes treescap.gif through giftool -p 4,5 and then through giftool -b 2 in a second invocation, then verifies gifbuild -d shows image left 4 and image top 5 on the resulting frame and giftext reports BackGround = 2, exercising independent composition of the position and background transforms.
# @timeout: 60
# @tags: usage, cli, giftool, chain
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -p 4,5 <"$gif"             >"$tmpdir/positioned.gif"
giftool -b 2   <"$tmpdir/positioned.gif" >"$tmpdir/final.gif"

file "$tmpdir/final.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/final.gif" >"$tmpdir/dump.txt"
grep -qE '^[[:space:]]*image left 4$'  "$tmpdir/dump.txt" || {
  printf 'expected "image left 4" in gifbuild dump after -p 4,5\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
}
grep -qE '^[[:space:]]*image top 5$'   "$tmpdir/dump.txt" || {
  printf 'expected "image top 5" in gifbuild dump after -p 4,5\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
}

giftext "$tmpdir/final.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 2'
