#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-fire-palette-row
# @title: gifclrmp fire palette row
# @description: Prints the fire.gif color map with gifclrmp and verifies that at least one palette row is emitted.
# @timeout: 180
# @tags: usage, gif, gifclrmp
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifclrmp-fire-palette-row"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifclrmp "$samples/fire.gif" | tee "$tmpdir/out"
color_row "$tmpdir/out"
