#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-treescap-colormap
# @title: giffix treescap colormap
# @description: Runs giffix on the treescap fixture and verifies the fixed GIF still exposes a color map through gifclrmp.
# @timeout: 180
# @tags: usage, gif, giffix
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-treescap-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
gifclrmp "$tmpdir/fixed.gif" | tee "$tmpdir/out"
color_row "$tmpdir/out"
