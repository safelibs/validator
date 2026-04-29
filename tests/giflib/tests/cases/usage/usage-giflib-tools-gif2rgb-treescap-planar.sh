#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-treescap-planar
# @title: gif2rgb treescap planar output
# @description: Converts the treescap fixture to planar RGB output with gif2rgb and verifies the three channel files exist.
# @timeout: 180
# @tags: usage, gif, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-treescap-planar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gif2rgb -o "$tmpdir/treescap" "$samples/treescap.gif"
validator_require_file "$tmpdir/treescap.R"
validator_require_file "$tmpdir/treescap.G"
validator_require_file "$tmpdir/treescap.B"
