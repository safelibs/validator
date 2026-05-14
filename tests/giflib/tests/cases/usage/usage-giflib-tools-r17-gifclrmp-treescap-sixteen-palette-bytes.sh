#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-gifclrmp-treescap-sixteen-palette-bytes
# @title: gifclrmp -s on treescap.gif emits a palette dump with at least 16 entry rows
# @description: Runs gifclrmp -s on treescap.gif to dump the palette as text and asserts the output contains at least 16 non-empty lines, exercising the palette emission on the known treescap fixture without pinning the exact line count.
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
nonempty=$(grep -cE '[^[:space:]]' "$tmpdir/palette.txt" || true)
(( nonempty >= 16 )) || {
    printf 'expected at least 16 non-empty palette lines, got %s\n' "$nonempty" >&2
    sed -n '1,40p' "$tmpdir/palette.txt" >&2
    exit 1
}
