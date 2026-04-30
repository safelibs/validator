#!/usr/bin/env bash
# @testcase: usage-pngquant-quality-min-only-png
# @title: pngquant single-value quality cap PNG
# @description: Runs pngquant with a single high quality cap and confirms PNG output is produced.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --quality=80 --force --output "$tmpdir/out.png" 256 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
