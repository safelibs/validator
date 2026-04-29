#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-fire-colormap-row
# @title: giftext fire color map row
# @description: Prints the fire.gif color map with giftext -c and verifies that at least one numeric palette row is emitted.
# @timeout: 180
# @tags: usage, gif, giftext
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-fire-colormap-row"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giftext -c "$samples/fire.gif" | tee "$tmpdir/out"
grep -Eq '^[[:space:]]*0:' "$tmpdir/out"
