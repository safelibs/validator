#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-gifclrmp-fire-palette-256-rows
# @title: gifclrmp -s on fire.gif emits exactly 256 palette rows
# @description: Dumps fire.gif's global palette via gifclrmp -s and asserts the output has exactly 256 rows (the GIF87a/89a maximum global colormap size for an 8-bit-per-pixel encoded animation), exercising the palette-extraction path on a multi-frame fixture.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/cmap.txt"
[[ -s "$tmpdir/cmap.txt" ]]

rows=$(wc -l <"$tmpdir/cmap.txt")
[[ "$rows" -eq 256 ]] || {
    printf 'expected 256 rows, got %s\n' "$rows" >&2
    exit 1
}
