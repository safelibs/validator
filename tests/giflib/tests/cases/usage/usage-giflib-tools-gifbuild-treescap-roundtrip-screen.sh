#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-treescap-roundtrip-screen
# @title: gifbuild treescap roundtrip screen
# @description: Dumps treescap.gif to gifbuild text, rebuilds it, and verifies screen metadata from the rebuilt GIF.
# @timeout: 180
# @tags: usage, gif, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-treescap-roundtrip-screen"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifbuild -d "$samples/treescap.gif" >"$tmpdir/tree.txt"
gifbuild "$tmpdir/tree.txt" >"$tmpdir/tree.gif"
giftext "$tmpdir/tree.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
