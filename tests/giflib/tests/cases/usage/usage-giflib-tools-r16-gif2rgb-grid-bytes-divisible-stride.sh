#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-gif2rgb-grid-bytes-divisible-stride
# @title: gif2rgb -1 gifgrid.gif byte count divisible by width*3
# @description: Decodes gifgrid.gif via gif2rgb -1 and asserts the emitted RGB byte count is positive, divisible by width*3 (no row padding) and divisible by width*height*3 (whole-frame multiple), exercising the stride contract on the synthetic grid fixture distinct from the treescap and fire cases.
# @timeout: 60
# @tags: usage, cli, gif2rgb, stride
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
size_line=$(grep -E 'Screen Size - Width = [0-9]+, Height = [0-9]+' "$tmpdir/info.txt" | head -n1)
w=$(printf '%s' "$size_line" | sed -n 's/.*Width = \([0-9]*\).*/\1/p')
h=$(printf '%s' "$size_line" | sed -n 's/.*Height = \([0-9]*\).*/\1/p')
(( w > 0 && h > 0 ))

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
bytes=$(stat -c '%s' "$tmpdir/out.rgb")
(( bytes > 0 ))
row=$((w * 3))
frame=$((row * h))
(( bytes % row == 0 )) || { printf 'bytes=%s row=%s\n' "$bytes" "$row" >&2; exit 1; }
(( bytes % frame == 0 )) || { printf 'bytes=%s frame=%s\n' "$bytes" "$frame" >&2; exit 1; }
