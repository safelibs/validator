#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-interlaced
# @title: gif2rgb interlaced conversion
# @description: Converts an interlaced GIF fixture to RGB bytes and compares the expected output.
# @timeout: 180
# @tags: usage, gif, conversion
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-interlaced"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
expected="$VALIDATOR_SAMPLE_ROOT/tests/treescap-interlaced.rgb"
validator_require_file "$gif"
validator_require_file "$expected"
gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
cmp "$expected" "$tmpdir/out.rgb"
