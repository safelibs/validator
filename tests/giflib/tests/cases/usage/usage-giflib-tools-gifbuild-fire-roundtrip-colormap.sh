#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-roundtrip-colormap
# @title: gifbuild fire roundtrip colormap
# @description: Dumps and rebuilds the fire fixture with gifbuild and verifies the rebuilt GIF still exposes a color map through gifclrmp.
# @timeout: 180
# @tags: usage, gif, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-fire-roundtrip-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifbuild -d "$samples/fire.gif" >"$tmpdir/fire.txt"
gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
gifclrmp "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
color_row "$tmpdir/out"
