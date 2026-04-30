#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-rgb-to-gif-roundtrip
# @title: gif2rgb -s converts RGB stream back to GIF
# @description: Decodes a fixture to raw RGB triplets, then uses gif2rgb -s to encode that stream back into a GIF whose dimensions and decoded byte count match the original.
# @timeout: 120
# @tags: usage, cli, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

# 100x100 fixture -> 30000 RGB bytes
gif2rgb -1 -o "$tmpdir/grid.rgb" "$gif"
[[ "$(wc -c <"$tmpdir/grid.rgb")" -eq 30000 ]]

gif2rgb -s 100 100 <"$tmpdir/grid.rgb" >"$tmpdir/encoded.gif"
file "$tmpdir/encoded.gif" | grep -q 'GIF image data'

giftext "$tmpdir/encoded.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Width = 100, Height = 100'

gif2rgb -1 -o "$tmpdir/decoded.rgb" "$tmpdir/encoded.gif"
[[ "$(wc -c <"$tmpdir/decoded.rgb")" -eq 30000 ]]
