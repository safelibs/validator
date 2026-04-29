#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-giffix-grid-rgb-output
# @title: giffix grid RGB output
# @description: Repairs the grid fixture with giffix and checks RGB conversion still produces data.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-giffix-grid-rgb-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

giffix "$samples/gifgrid.gif" >"$tmpdir/fixed.gif"
gif2rgb -1 -o "$tmpdir/fixed.rgb" "$tmpdir/fixed.gif"
require_nonempty "$tmpdir/fixed.rgb"
