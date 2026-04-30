#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-bg-chain-final-index
# @title: giftext reports only the final -b after a giftool background chain
# @description: Pipes treescap.gif through giftool -b 5, then giftool -b 9, and verifies giftext on the final stream reports BackGround = 9 with no remaining BackGround = 5 record, demonstrating that successive -b transforms overwrite the screen background field rather than accumulating.
# @timeout: 60
# @tags: usage, cli, giftool, giftext, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Stage 1.
giftool -b 5 <"$gif" >"$tmpdir/bg5.gif"
file "$tmpdir/bg5.gif" | grep -q 'GIF image data'
giftext "$tmpdir/bg5.gif" >"$tmpdir/info5.txt"
validator_assert_contains "$tmpdir/info5.txt" 'BackGround = 5'

# Stage 2: overwrite the background index.
giftool -b 9 <"$tmpdir/bg5.gif" >"$tmpdir/bg9.gif"
file "$tmpdir/bg9.gif" | grep -q 'GIF image data'

giftext "$tmpdir/bg9.gif" >"$tmpdir/info9.txt"
validator_assert_contains "$tmpdir/info9.txt" 'BackGround = 9'

# The intermediate index must NOT survive the second -b pass.
if grep -q 'BackGround = 5' "$tmpdir/info9.txt"; then
  printf 'BackGround = 5 unexpectedly persisted after giftool -b 9 override\n' >&2
  sed -n '1,40p' "$tmpdir/info9.txt" >&2
  exit 1
fi

# Cross-check: gifbuild dump must not show any "background 5" record either.
gifbuild -d "$tmpdir/bg9.gif" >"$tmpdir/dump.txt"
if grep -qE '^[[:space:]]*background[[:space:]]+5\b' "$tmpdir/dump.txt"; then
  printf 'gifbuild dump still references background 5\n' >&2
  exit 1
fi
