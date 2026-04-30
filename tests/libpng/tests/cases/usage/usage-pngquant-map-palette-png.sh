#!/usr/bin/env bash
# @testcase: usage-pngquant-map-palette-png
# @title: pngquant map external palette PNG
# @description: Quantizes a PNG using an external palette PNG via pngquant --map and verifies PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

# Build a small palette PNG by quantizing the same fixture to a few colors.
pngquant --force --output "$tmpdir/palette.png" 8 "$png"
file "$tmpdir/palette.png" | tee "$tmpdir/palette-file"
validator_assert_contains "$tmpdir/palette-file" 'PNG image data'

pngquant --map "$tmpdir/palette.png" --force --output "$tmpdir/out.png" 256 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/out-file"
validator_assert_contains "$tmpdir/out-file" 'PNG image data'
