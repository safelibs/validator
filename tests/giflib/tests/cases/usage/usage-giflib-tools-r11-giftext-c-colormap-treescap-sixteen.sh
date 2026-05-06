#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-giftext-c-colormap-treescap-sixteen
# @title: giftext -c lists exactly sixteen global colormap entries for treescap
# @description: Runs giftext -c on the treescap fixture and counts colormap rows of the form "<idx>: <r>h <g>h <b>h" in the global color map block, asserting exactly 16 entries (matches BitsPerPixel=4).
# @timeout: 60
# @tags: usage, cli, giftext, colormap
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext -c "$gif" >"$tmpdir/dump.txt"

# Each entry appears once per multi-column row layout. Use a tolerant
# regex that matches "<idx>:<spaces><hex>h" tokens regardless of column
# wrapping and counts unique color indices 0..15.
entries=$(grep -oE '[[:space:]][0-9]+: [0-9a-f]+h' "$tmpdir/dump.txt" | wc -l)
if [[ "$entries" -ne 16 ]]; then
    printf 'expected 16 colormap entries, counted %s\n' "$entries" >&2
    sed -n '1,30p' "$tmpdir/dump.txt" >&2
    exit 1
fi
