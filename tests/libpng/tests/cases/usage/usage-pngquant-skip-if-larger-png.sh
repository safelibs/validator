#!/usr/bin/env bash
# @testcase: usage-pngquant-skip-if-larger-png
# @title: pngquant skip-if-larger
# @description: Runs pngquant with skip-if-larger enabled and accepts either optimized output or skip status.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-skip-if-larger-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

if pngquant --skip-if-larger --force --output "$tmpdir/out.png" 256 "$png"; then
  assert_png "$tmpdir/out.png"
else
  test ! -e "$tmpdir/out.png"
  printf 'pngquant skipped larger output\n'
fi
