#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-gif2rgb-gifgrid-raster-size-30000
# @title: gif2rgb -1 -o on gifgrid.gif emits a 30000-byte raster equal to width*height*3
# @description: Runs gif2rgb -1 -o on the 100x100 gifgrid.gif fixture and asserts the output file size equals exactly 30000 bytes which is width*height*3 for a single-frame extract, exercising the raster sizing invariant on the grid fixture distinct from prior treescap and fire size tests.
# @timeout: 60
# @tags: usage, cli, gif2rgb, raster, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
size=$(stat -c '%s' "$tmpdir/out.rgb")
[[ "$size" == "30000" ]] || {
    printf 'expected size 30000, got %s\n' "$size" >&2
    exit 1
}
