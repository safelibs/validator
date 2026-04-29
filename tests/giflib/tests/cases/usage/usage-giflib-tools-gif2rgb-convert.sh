#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-convert
# @title: giflib-tools gif2rgb convert
# @description: Runs giflib-tools gif2rgb convert on a GIF fixture and checks image metadata.
# @timeout: 180
# @tags: usage, cli, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
validator_require_file "$tmpdir/out.rgb"
wc -c "$tmpdir/out.rgb"
