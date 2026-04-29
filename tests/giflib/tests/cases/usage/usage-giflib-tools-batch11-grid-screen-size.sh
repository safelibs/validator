#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-grid-screen-size
# @title: giftext grid screen size
# @description: Runs giftext on the grid fixture and checks screen size metadata is present.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-grid-screen-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

giftext "$samples/gifgrid.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size - Width'
