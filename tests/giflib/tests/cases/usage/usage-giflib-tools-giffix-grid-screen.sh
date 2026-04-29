#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-grid-screen
# @title: giffix grid screen header
# @description: Runs giffix on the grid fixture and verifies the repaired GIF still exposes screen metadata through giftext.
# @timeout: 180
# @tags: usage, gif, giffix
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-grid-screen"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giffix "$samples/gifgrid.gif" >"$tmpdir/fixed.gif"
giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
