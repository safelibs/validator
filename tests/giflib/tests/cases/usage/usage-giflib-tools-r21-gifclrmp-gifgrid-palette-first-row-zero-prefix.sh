#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-gifclrmp-gifgrid-palette-first-row-zero-prefix
# @title: gifclrmp -s on gifgrid.gif palette dump first row begins with index 0
# @description: Runs gifclrmp -s on gifgrid.gif and asserts the first non-empty line of the palette dump starts with the literal token "0" (index zero) followed by whitespace and three integer RGB values, exercising the index-prefix shape of the palette dump on gifgrid distinct from prior row-count and palette-bytes tests.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette, gifgrid, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/pal.txt"

first=$(awk 'NF{print; exit}' "$tmpdir/pal.txt")
echo "first line: $first" >&2

# Expect index 0 followed by three RGB integers.
if ! [[ "$first" =~ ^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+ ]]; then
    printf 'first palette row did not match "0 R G B" shape: %s\n' "$first" >&2
    exit 1
fi
