#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-image-index-vs-global
# @title: gifclrmp -i 5 -g rewrites only image #5 while -g alone rewrites the whole map
# @description: Applies the same gamma value via gifclrmp twice on fire.gif -- once globally with -g 0.5 and once scoped to a single frame with -i 5 -g 0.5 -- and verifies the two outputs differ from each other and from the original, that both remain parseable GIFs with the original frame count and screen size, anchoring the per-image scoping behavior of -i.
# @timeout: 60
# @tags: usage, cli, gifclrmp, gamma, image-index
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifclrmp -g 0.5 "$gif" >"$tmpdir/global.gif"
gifclrmp -i 5 -g 0.5 "$gif" >"$tmpdir/i5.gif"

file "$tmpdir/global.gif" | grep -q 'GIF image data'
file "$tmpdir/i5.gif"     | grep -q 'GIF image data'

if cmp -s "$tmpdir/global.gif" "$tmpdir/i5.gif"; then
  printf 'expected -g and -i 5 -g to produce different outputs\n' >&2
  exit 1
fi
if cmp -s "$gif" "$tmpdir/i5.gif"; then
  printf 'expected -i 5 -g to modify the source\n' >&2
  exit 1
fi
if cmp -s "$gif" "$tmpdir/global.gif"; then
  printf 'expected -g (global) to modify the source\n' >&2
  exit 1
fi

giftext "$gif"               >"$tmpdir/orig.txt"
giftext "$tmpdir/global.gif" >"$tmpdir/global.txt"
giftext "$tmpdir/i5.gif"     >"$tmpdir/i5.txt"

orig_frames=$(grep -cE '^Image #[0-9]+:' "$tmpdir/orig.txt" || true)
global_frames=$(grep -cE '^Image #[0-9]+:' "$tmpdir/global.txt" || true)
i5_frames=$(grep -cE '^Image #[0-9]+:' "$tmpdir/i5.txt" || true)
if [[ "$orig_frames" != "$global_frames" || "$orig_frames" != "$i5_frames" ]]; then
  printf 'frame count drift: orig=%s global=%s i5=%s\n' \
    "$orig_frames" "$global_frames" "$i5_frames" >&2
  exit 1
fi

orig_screen=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/orig.txt" | head -n 1)
i5_screen=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/i5.txt" | head -n 1)
if [[ "$orig_screen" != "$i5_screen" ]]; then
  printf 'screen size drift: orig=%q i5=%q\n' "$orig_screen" "$i5_screen" >&2
  exit 1
fi
