#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-gifbuild-fire-rgb-compare
# @title: gifbuild fire RGB parity
# @description: Rebuilds the fire fixture from gifbuild text and compares the RGB output.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-gifbuild-fire-rgb-compare"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

gifbuild -d "$samples/fire.gif" >"$tmpdir/fire.txt"
gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
gif2rgb -1 -o "$tmpdir/rebuilt.rgb" "$tmpdir/rebuilt.gif"
cmp "$tests_root/fire.rgb" "$tmpdir/rebuilt.rgb"
