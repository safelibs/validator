#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-size
# @title: gif2rgb fire RGB size
# @description: Converts fire.gif to a single RGB file and checks the byte count is nonzero.
# @timeout: 180
# @tags: usage, gif, conversion
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-fire-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"
gif2rgb -1 -o "$tmpdir/fire.rgb" "$gif"
test "$(wc -c <"$tmpdir/fire.rgb")" -gt 0
