#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-gifclrmp-treescap-sixteen-entries
# @title: gifclrmp -s on treescap dumps a sixteen-entry palette
# @description: Runs gifclrmp -s on the treescap fixture (BitsPerPixel=4) and verifies the dumped palette has exactly 16 lines, each three space-separated decimal channel values within 0..255.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/palette.txt"

count=$(wc -l <"$tmpdir/palette.txt")
if [[ "$count" -ne 16 ]]; then
    printf 'expected 16 palette rows, got %s\n' "$count" >&2
    sed -n '1,5p' "$tmpdir/palette.txt" >&2
    exit 1
fi

awk '{
    if (NF < 4) { exit 1 }
    for (i = 2; i <= 4; i++) {
        if ($i < 0 || $i > 255) { exit 1 }
    }
}' "$tmpdir/palette.txt"
