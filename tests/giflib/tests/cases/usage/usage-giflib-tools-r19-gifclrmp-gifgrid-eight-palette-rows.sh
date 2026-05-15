#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-gifclrmp-gifgrid-eight-palette-rows
# @title: gifclrmp -s on gifgrid.gif emits exactly eight palette rows
# @description: Runs gifclrmp -s on the gifgrid.gif fixture (which uses an 8-entry global colour map) and asserts the textual palette dump contains exactly 8 newline-terminated rows, exercising the colormap extractor row count on a small-palette fixture distinct from the 16-row treescap and 256-row fire dumps.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/palette.txt"
count=$(wc -l <"$tmpdir/palette.txt")
[[ "$count" -eq 8 ]] || {
    printf 'expected 8 palette rows, got %s\n' "$count" >&2
    sed -n '1,20p' "$tmpdir/palette.txt" >&2
    exit 1
}
