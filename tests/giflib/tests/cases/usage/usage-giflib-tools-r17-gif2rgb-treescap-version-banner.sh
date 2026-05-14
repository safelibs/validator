#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-gif2rgb-treescap-version-banner
# @title: gif2rgb -1 -o on treescap.gif emits a non-empty raster and prints to stderr without GIF header
# @description: Runs gif2rgb -1 -o on treescap.gif to extract the first frame as a raw RGB raster, asserts the output file is non-empty and does NOT start with the ASCII bytes "GIF" (because the raster is raw pixels, not a GIF stream), exercising the raw-output side of the GIF reader.
# @timeout: 60
# @tags: usage, cli, gif2rgb, raster
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
[[ -s "$tmpdir/out.rgb" ]]
head -c 3 "$tmpdir/out.rgb" >"$tmpdir/magic"
if grep -q 'GIF' "$tmpdir/magic"; then
    printf 'raw RGB raster unexpectedly starts with GIF magic\n' >&2
    exit 1
fi
