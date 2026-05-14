#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-gifclrmp-treescap-palette-three-columns
# @title: gifclrmp -s on treescap.gif emits palette lines with four integer columns each
# @description: Runs gifclrmp -s on treescap.gif to dump the colormap in text form, asserts the dump file is non-empty and that every line contains exactly four whitespace-separated numeric tokens corresponding to index plus RGB triple, exercising the textual colormap extractor row invariant.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/palette.txt"
[[ -s "$tmpdir/palette.txt" ]]

awk '{
    if (NF != 4) { exit 2 }
    for (i = 1; i <= 4; i++) {
        if ($i !~ /^[0-9]+$/) { exit 3 }
    }
}' "$tmpdir/palette.txt"
