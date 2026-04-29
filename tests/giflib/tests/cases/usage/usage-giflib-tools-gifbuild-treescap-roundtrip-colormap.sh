#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-treescap-roundtrip-colormap
# @title: gifbuild treescap roundtrip color map
# @description: Roundtrips treescap.gif through gifbuild dump and rebuild, then verifies that gifclrmp on the rebuilt gif emits a palette row.
# @timeout: 180
# @tags: usage, gif, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-treescap-roundtrip-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifbuild -d "$samples/treescap.gif" >"$tmpdir/tree.txt"
gifbuild "$tmpdir/tree.txt" >"$tmpdir/rebuilt.gif"
gifclrmp "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
color_row "$tmpdir/out"
