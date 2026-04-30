#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-fire-bg-delay-chain
# @title: giftool -b and -d combined on animated fire fixture
# @description: Pipes the multi-frame fire.gif through giftool with both a -b background index and a -d delay value in a single invocation, then asserts the gifbuild dump shows the new delay and giftext records the new background index, exercising two independent giftool transforms on an animated input.
# @timeout: 60
# @tags: usage, cli, giftool, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Confirm the source is an animated 89a stream so the GCE delay assertion is meaningful.
file "$gif" | grep -q 'version 89a'

giftool -b 7 -d 50 <"$gif" >"$tmpdir/combined.gif"
file "$tmpdir/combined.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/combined.gif" >"$tmpdir/dump.txt"
# At least one graphics control extension must carry the requested delay.
if ! grep -qE '^[[:space:]]+delay 50$' "$tmpdir/dump.txt"; then
  printf 'expected at least one "delay 50" line in gifbuild dump\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi

giftext "$tmpdir/combined.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'BackGround = 7'
