#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-synth-1x1-color-count
# @title: giftext describes a synthesized 1x1 GIF correctly
# @description: Synthesizes a single-pixel RGB triple, encodes it into a 1x1 GIF with gif2rgb -s, and asserts giftext reports the minimal screen size and the presence of an image record, exercising the giftext metadata path on the smallest possible GIF.
# @timeout: 60
# @tags: usage, cli, giftext, minimal
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Synthesize an RGB triple (not derived from a checked-in fixture so this
# test does not duplicate any pic/-based encoding case).
python3 -c '
import sys
with open(sys.argv[1], "wb") as fh:
    fh.write(bytes([17, 240, 99]))
' "$tmpdir/pixel.rgb"
[[ "$(wc -c <"$tmpdir/pixel.rgb")" -eq 3 ]]

gif2rgb -s 1 1 <"$tmpdir/pixel.rgb" >"$tmpdir/tiny.gif"
file "$tmpdir/tiny.gif" | grep -q 'GIF image data'

giftext "$tmpdir/tiny.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Width = 1, Height = 1'
# Exactly one image record.
image_count=$(grep -cE '^Image #[0-9]+:' "$tmpdir/info.txt" || true)
if [[ "$image_count" != "1" ]]; then
  printf 'expected exactly 1 image record, got %s\n' "$image_count" >&2
  sed -n '1,80p' "$tmpdir/info.txt" >&2
  exit 1
fi
