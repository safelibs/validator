#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-interlaced
# @title: gifclrmp interlaced fixture
# @description: Prints the color map for the interlaced treescap fixture with gifclrmp and verifies a palette row is emitted.
# @timeout: 180
# @tags: usage, gif, gifclrmp
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifclrmp-interlaced"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifclrmp "$samples/treescap-interlaced.gif" | tee "$tmpdir/out"
color_row "$tmpdir/out"
