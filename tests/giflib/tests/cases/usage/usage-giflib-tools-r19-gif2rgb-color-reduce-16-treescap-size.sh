#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-gif2rgb-color-reduce-16-treescap-size
# @title: gif2rgb -c 16 -1 -o on treescap.gif still emits a 4800-byte raster (40x40x3)
# @description: Runs gif2rgb -c 16 -1 -o on treescap.gif to request a 16-colour reduction and asserts the output raster file is still exactly 4800 bytes (width 40 * height 40 * 3 bytes per pixel), exercising the -c color-reduction option as a size-preserving operation distinct from previously tested invocations.
# @timeout: 60
# @tags: usage, cli, gif2rgb, color-reduce, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gif2rgb -c 16 -1 -o "$tmpdir/out.rgb" "$gif"
size=$(stat -c '%s' "$tmpdir/out.rgb")
[[ "$size" == "4800" ]] || {
    printf 'expected size 4800, got %s\n' "$size" >&2
    exit 1
}
