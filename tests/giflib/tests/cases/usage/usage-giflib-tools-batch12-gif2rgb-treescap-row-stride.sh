#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-gif2rgb-treescap-row-stride
# @title: gif2rgb treescap RGB output divides evenly by row*3
# @description: Runs gif2rgb -1 on the treescap GIF and confirms the RGB byte count is an exact multiple of the screen width times 3 (row-stride invariant).
# @timeout: 60
# @tags: usage, cli, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"

giftext "$gif" >"$tmpdir/text.out"
w=$(sed -n 's/.*Screen Size - Width = \([0-9]*\), Height = \([0-9]*\)\..*/\1/p' "$tmpdir/text.out" | head -n1)
[[ -n "$w" ]]
row_bytes=$((w * 3))

actual=$(stat -c '%s' "$tmpdir/out.rgb")
[[ "$actual" -gt 0 ]]
[[ $((actual % row_bytes)) == 0 ]]
