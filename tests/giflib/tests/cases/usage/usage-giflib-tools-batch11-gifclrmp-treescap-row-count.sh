#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-gifclrmp-treescap-row-count
# @title: gifclrmp treescap rows
# @description: Lists the treescap color map and checks multiple color rows are emitted.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-gifclrmp-treescap-row-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

gifclrmp "$samples/treescap.gif" >"$tmpdir/map.txt"
test "$(grep -Ec '^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/map.txt")" -gt 1
