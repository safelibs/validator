#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-grid-build-dump-size
# @title: gifbuild grid dump size
# @description: Dumps the grid fixture with gifbuild and checks textual screen data is produced.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-grid-build-dump-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

gifbuild -d "$samples/gifgrid.gif" >"$tmpdir/grid.txt"
require_nonempty "$tmpdir/grid.txt"
validator_assert_contains "$tmpdir/grid.txt" 'screen'
