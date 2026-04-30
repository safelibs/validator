#!/usr/bin/env bash
# @testcase: usage-pngquant-iebug-png
# @title: pngquant iebug workaround PNG
# @description: Exercises the pngquant --iebug legacy-IE compatibility flag and verifies PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --iebug --force --output "$tmpdir/out.png" 64 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
