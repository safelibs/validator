#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-treescap-rgb-nonempty
# @title: gif2rgb treescap RGB output
# @description: Converts the treescap fixture to packed RGB and checks bytes are produced.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-treescap-rgb-nonempty"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

gif2rgb -1 -o "$tmpdir/tree.rgb" "$samples/treescap.gif"
require_nonempty "$tmpdir/tree.rgb"
