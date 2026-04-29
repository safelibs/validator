#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-rgb-bytes
# @title: gif2rgb fire RGB bytes
# @description: Converts the fire.gif fixture to an RGB byte stream with gif2rgb and verifies that non-empty RGB output is produced.
# @timeout: 180
# @tags: usage, gif, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-fire-rgb-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gif2rgb -1 -o "$tmpdir/fire.rgb" "$samples/fire.gif"
test "$(wc -c <"$tmpdir/fire.rgb")" -gt 0
