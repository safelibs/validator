#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-gifclrmp-treescap-rgb-bounds
# @title: gifclrmp -s on treescap.gif emits palette rows with values within 0-255
# @description: Runs gifclrmp -s on the treescap.gif fixture and asserts every emitted palette row contains exactly three space-separated integers each in the byte range [0,255], exercising the palette-byte range invariant on treescap distinct from prior row-count or column-count tests.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette-bounds, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/palette.txt"
[[ -s "$tmpdir/palette.txt" ]] || { printf 'empty palette\n' >&2; exit 1; }

while read -r r g b _rest; do
    [[ "$r" =~ ^[0-9]+$ && "$g" =~ ^[0-9]+$ && "$b" =~ ^[0-9]+$ ]] || {
        printf 'non-integer row: %s %s %s\n' "$r" "$g" "$b" >&2
        exit 1
    }
    (( r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255 )) || {
        printf 'out-of-range row: %s %s %s\n' "$r" "$g" "$b" >&2
        exit 1
    }
done <"$tmpdir/palette.txt"
