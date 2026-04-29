#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-treescap-screen-size
# @title: giffix treescap screen size
# @description: Repairs the treescap.gif fixture with giffix and verifies that giftext can still read screen metadata from the result.
# @timeout: 180
# @tags: usage, gif, giffix
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-treescap-screen-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
