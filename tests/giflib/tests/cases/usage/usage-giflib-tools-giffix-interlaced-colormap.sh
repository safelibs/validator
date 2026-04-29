#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-interlaced-colormap
# @title: giffix color map
# @description: Exercises giffix color map through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-interlaced-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

giffix "$samples/gifgrid.gif" >"$tmpdir/fixed.gif"
gifclrmp "$tmpdir/fixed.gif" | tee "$tmpdir/out"
grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
