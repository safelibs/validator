#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-bg-roundtrip-idempotent
# @title: giftool -b applied twice with the same value is idempotent
# @description: Pipes treescap.gif through giftool -b 3 and then through a second giftool -b 3 invocation and verifies the two outputs are byte-identical and giftext reports BackGround = 3, demonstrating idempotence of the background-index transform under repeated application.
# @timeout: 60
# @tags: usage, cli, giftool, idempotent
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 3 <"$gif"            >"$tmpdir/once.gif"
giftool -b 3 <"$tmpdir/once.gif" >"$tmpdir/twice.gif"

file "$tmpdir/once.gif"  | grep -q 'GIF image data'
file "$tmpdir/twice.gif" | grep -q 'GIF image data'

# Byte-exact equality: applying the same transform a second time must be a no-op.
if ! cmp -s "$tmpdir/once.gif" "$tmpdir/twice.gif"; then
  printf 'giftool -b 3 was not idempotent: outputs differ\n' >&2
  ls -l "$tmpdir/once.gif" "$tmpdir/twice.gif" >&2
  exit 1
fi

giftext "$tmpdir/twice.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 3'
