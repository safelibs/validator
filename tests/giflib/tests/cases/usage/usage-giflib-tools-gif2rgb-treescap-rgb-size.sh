#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-treescap-rgb-size
# @title: gif2rgb treescap RGB size
# @description: Converts treescap.gif to packed RGB output with gif2rgb and verifies the emitted byte stream is nonempty.
# @timeout: 180
# @tags: usage, gif, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-treescap-rgb-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gif2rgb -1 -o "$tmpdir/treescap.rgb" "$gif"
test "$(wc -c <"$tmpdir/treescap.rgb")" -gt 0
