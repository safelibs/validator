#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-gif2rgb-fire-output-size-multiple-of-three
# @title: gif2rgb -1 -o on fire.gif emits a raster sized as a multiple of three bytes
# @description: Runs gif2rgb -1 -o on fire.gif to extract the first frame as a raw RGB raster and asserts the output file size is divisible by 3 because each pixel occupies exactly three RGB bytes, exercising the raster packing invariant on the multi-frame animation fixture.
# @timeout: 60
# @tags: usage, cli, gif2rgb, raster, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
[[ -s "$tmpdir/out.rgb" ]]
size=$(stat -c '%s' "$tmpdir/out.rgb")
if (( size % 3 != 0 )); then
    printf 'expected size divisible by 3, got %s\n' "$size" >&2
    exit 1
fi
