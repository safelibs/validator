#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-grid-bits-per-pixel
# @title: giftext grid bits per pixel
# @description: Reads the gifgrid fixture with giftext and verifies that the bits-per-pixel metadata line is emitted.
# @timeout: 180
# @tags: usage, gif, giftext
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-grid-bits-per-pixel"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giftext "$samples/gifgrid.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'BitsPerPixel'
