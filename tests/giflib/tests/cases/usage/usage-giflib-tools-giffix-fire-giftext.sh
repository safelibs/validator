#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-fire-giftext
# @title: giffix giftext output
# @description: Exercises giffix giftext output through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-fire-giftext"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Image'
