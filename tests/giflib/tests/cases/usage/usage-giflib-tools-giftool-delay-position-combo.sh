#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-delay-position-combo
# @title: giftool combines -d and -p in one invocation
# @description: Invokes giftool with -d 50 and -p 2,3 in a single command on gifgrid.gif and verifies gifbuild dumps the requested delay 50 and an image with left 2 and top 3, confirming both transforms were applied in one pass without one clobbering the other.
# @timeout: 60
# @tags: usage, cli, giftool, combo
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftool -d 50 -p 2,3 <"$gif" >"$tmpdir/combo.gif"
file "$tmpdir/combo.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/combo.gif" >"$tmpdir/dump.txt"

# Delay 50 must appear at least once in the gifbuild dump.
if ! grep -qE '^[[:space:]]*delay 50$' "$tmpdir/dump.txt"; then
  printf 'expected "delay 50" line in gifbuild dump\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi

# Image left 2 and image top 3 must appear together for at least one frame.
if ! grep -qE '^[[:space:]]*image left 2$' "$tmpdir/dump.txt"; then
  printf 'expected "image left 2" line in gifbuild dump\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi
if ! grep -qE '^[[:space:]]*image top 3$' "$tmpdir/dump.txt"; then
  printf 'expected "image top 3" line in gifbuild dump\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi
