#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-set-transparency
# @title: giftool -d sets per-frame delay
# @description: Applies a giftool -d delay value to a GIF fixture and verifies the resulting graphics control extension reports the requested delay in the gifbuild text dump.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -d 42 <"$gif" >"$tmpdir/delayed.gif"
file "$tmpdir/delayed.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/delayed.gif" >"$tmpdir/dump.txt"
# gifbuild dumps the GCE delay as `\tdelay 42` (tab-indented). Require at
# least one matching line so we know the new delay was written into a GCE.
if ! grep -qE '^[[:space:]]+delay 42$' "$tmpdir/dump.txt"; then
  printf 'expected gifbuild dump to contain "delay 42" graphics-control line\n' >&2
  sed -n '1,80p' "$tmpdir/dump.txt" >&2
  exit 1
fi
