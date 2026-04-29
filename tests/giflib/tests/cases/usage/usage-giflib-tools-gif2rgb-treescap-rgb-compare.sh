#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-treescap-rgb-compare
# @title: gif2rgb treescap interlaced rgb compare
# @description: Decodes treescap-interlaced.gif with gif2rgb -1 and verifies the RGB output bytes match the recorded fixture.
# @timeout: 180
# @tags: usage, gif, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-treescap-rgb-compare"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gif2rgb -1 -o "$tmpdir/interlaced.rgb" "$samples/treescap-interlaced.gif"
cmp "$tests_root/treescap-interlaced.rgb" "$tmpdir/interlaced.rgb"
