#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-planar
# @title: giflib-tools gif2rgb planar output
# @description: Converts a GIF fixture into separate RGB planes with gif2rgb and verifies all channel files are produced.
# @timeout: 180
# @tags: usage, cli, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gif2rgb -o "$tmpdir/planes" "$gif"
validator_require_file "$tmpdir/planes.R"
validator_require_file "$tmpdir/planes.G"
validator_require_file "$tmpdir/planes.B"
wc -c "$tmpdir/planes.R" "$tmpdir/planes.G" "$tmpdir/planes.B"
