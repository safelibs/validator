#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-grid-color-map
# @title: giftext grid Global Color Map
# @description: Prints the gifgrid.gif color map with giftext -c and verifies that the Global Color Map heading is emitted.
# @timeout: 180
# @tags: usage, gif, giftext
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-grid-color-map"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giftext -c "$samples/gifgrid.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Global Color Map'
