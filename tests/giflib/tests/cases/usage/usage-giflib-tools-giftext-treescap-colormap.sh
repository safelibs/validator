#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-treescap-colormap
# @title: giftext treescap color map
# @description: Exercises giftext treescap color map through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-treescap-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

giftext -c "$samples/treescap.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Global Color Map'
