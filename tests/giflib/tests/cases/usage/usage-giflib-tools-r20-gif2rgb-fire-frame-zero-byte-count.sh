#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-gif2rgb-fire-frame-zero-byte-count
# @title: gif2rgb -1 -o 0 on fire.gif emits exactly 5400 bytes (30x60x3) for frame zero
# @description: Runs gif2rgb -1 -o on the multi-frame fire.gif fixture targeting frame zero by default first-frame mode and asserts the produced raster is exactly 5400 bytes (width 30 * height 60 * 3 bytes per pixel), exercising the explicit single-first-frame raster size on fire distinct from prior treescap and gifgrid size tests.
# @timeout: 60
# @tags: usage, cli, gif2rgb, frame-zero, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
size=$(stat -c '%s' "$tmpdir/out.rgb")
[[ "$size" == "5400" ]] || {
    printf 'expected size 5400, got %s\n' "$size" >&2
    exit 1
}
