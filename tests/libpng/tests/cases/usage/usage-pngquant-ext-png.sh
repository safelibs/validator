#!/usr/bin/env bash
# @testcase: usage-pngquant-ext-png
# @title: pngquant extension output
# @description: Uses pngquant extension output naming and checks the generated file.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-ext-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

cp "$png" "$tmpdir/input.png"
(cd "$tmpdir" && pngquant --force --ext .quant.png 16 input.png)
assert_png "$tmpdir/input.quant.png"
