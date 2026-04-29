#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-treescap-color-resolution
# @title: giftext treescap color resolution
# @description: Reads the treescap fixture with giftext and verifies the color resolution metadata is reported.
# @timeout: 180
# @tags: usage, gif, giftext
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-treescap-color-resolution"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giftext "$samples/treescap.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ColorResolution'
