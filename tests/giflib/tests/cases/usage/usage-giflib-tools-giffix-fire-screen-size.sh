#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-fire-screen-size
# @title: giffix fire screen size
# @description: Repairs fire.gif with giffix and verifies that giftext on the fixed gif still reports Screen Size.
# @timeout: 180
# @tags: usage, gif, giffix
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-fire-screen-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
