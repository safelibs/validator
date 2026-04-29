#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-grid-palette-row
# @title: gifclrmp grid palette row
# @description: Prints the gifgrid.gif color map with gifclrmp and verifies that at least one palette row is emitted.
# @timeout: 180
# @tags: usage, gif, gifclrmp
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifclrmp-grid-palette-row"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifclrmp "$samples/gifgrid.gif" | tee "$tmpdir/out"
color_row "$tmpdir/out"
