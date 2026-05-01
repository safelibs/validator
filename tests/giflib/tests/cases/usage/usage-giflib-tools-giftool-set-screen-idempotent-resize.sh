#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-set-screen-idempotent-resize
# @title: giftool -s applied twice with the same dimensions is byte-stable
# @description: Pipes treescap.gif through giftool -s 80,60 and feeds the result back through giftool -s 80,60 a second time, then asserts both outputs are byte-identical and giftext reports Width = 80, Height = 60 on the doubly-resized stream, demonstrating idempotence of the screen-descriptor rewrite.
# @timeout: 60
# @tags: usage, cli, giftool, idempotent
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -s 80,60 <"$gif"            >"$tmpdir/once.gif"
giftool -s 80,60 <"$tmpdir/once.gif" >"$tmpdir/twice.gif"

file "$tmpdir/once.gif"  | grep -q 'GIF image data'
file "$tmpdir/twice.gif" | grep -q 'GIF image data'

if ! cmp -s "$tmpdir/once.gif" "$tmpdir/twice.gif"; then
  printf 'giftool -s 80,60 was not idempotent: outputs differ\n' >&2
  ls -l "$tmpdir/once.gif" "$tmpdir/twice.gif" >&2
  exit 1
fi

giftext "$tmpdir/twice.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Width = 80, Height = 60'
