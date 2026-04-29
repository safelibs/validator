#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-interlaced-planar
# @title: gif2rgb interlaced planar output
# @description: Exercises gif2rgb interlaced planar output through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-interlaced-planar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

gif2rgb -o "$tmpdir/interlaced" "$samples/treescap-interlaced.gif"
validator_require_file "$tmpdir/interlaced.R"
validator_require_file "$tmpdir/interlaced.G"
validator_require_file "$tmpdir/interlaced.B"
test "$(wc -c <"$tmpdir/interlaced.R")" -gt 0
