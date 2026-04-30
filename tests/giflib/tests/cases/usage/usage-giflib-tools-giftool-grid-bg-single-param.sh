#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-grid-bg-single-param
# @title: giftool -b N updates background index on gifgrid
# @description: Reads the original BackGround index reported by giftext for gifgrid.gif, picks a sentinel index distinct from that value, runs giftool -b sentinel as the only transform, and confirms giftext on the result reports BackGround = sentinel and that the rewritten file is still recognized as GIF data.
# @timeout: 60
# @tags: usage, cli, giftool, single-param
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/before.txt"
orig_bg=$(grep -Eo 'BackGround = [0-9]+' "$tmpdir/before.txt" | head -n 1 | awk '{print $3}')
[[ "$orig_bg" =~ ^[0-9]+$ ]] || {
  printf 'could not parse BackGround from giftext: %q\n' "$orig_bg" >&2
  exit 1
}

# Pick a sentinel BackGround index that differs from the original; clamp into
# the typical 0..15 range so we stay inside the smallest plausible global
# colormap.
sentinel=$(( (orig_bg + 5) % 16 ))
if [[ "$sentinel" == "$orig_bg" ]]; then
  sentinel=$(( (sentinel + 1) % 16 ))
fi

giftool -b "$sentinel" <"$gif" >"$tmpdir/bg.gif"
file "$tmpdir/bg.gif" | grep -q 'GIF image data'

giftext "$tmpdir/bg.gif" >"$tmpdir/after.txt"
validator_assert_contains "$tmpdir/after.txt" "BackGround = $sentinel"

# And the reported value really did change.
if grep -qE "BackGround = $orig_bg\b" "$tmpdir/after.txt"; then
  printf 'BackGround did not change from %s; sentinel was %s\n' "$orig_bg" "$sentinel" >&2
  exit 1
fi
