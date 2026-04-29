#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-compare
# @title: gif2rgb fire RGB compare
# @description: Exercises gif2rgb fire rgb compare through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-fire-compare"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

gif2rgb -1 -o "$tmpdir/fire.rgb" "$samples/fire.gif"
cmp "$tests_root/fire.rgb" "$tmpdir/fire.rgb"
