#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-roundtrip-screen-size
# @title: gifbuild fire roundtrip screen size
# @description: Roundtrips fire.gif through gifbuild dump and rebuild, then verifies that the rebuilt giftext output reports Screen Size.
# @timeout: 180
# @tags: usage, gif, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-fire-roundtrip-screen-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifbuild -d "$samples/fire.gif" >"$tmpdir/fire.txt"
gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
