#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-interlaced-rgb-bytes
# @title: gif2rgb interlaced RGB bytes
# @description: Converts the interlaced treescap fixture to an RGB byte stream with gif2rgb and verifies that non-empty RGB output is produced.
# @timeout: 180
# @tags: usage, gif, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-interlaced-rgb-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gif2rgb -1 -o "$tmpdir/interlaced.rgb" "$samples/treescap-interlaced.gif"
test "$(wc -c <"$tmpdir/interlaced.rgb")" -gt 0
