#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-colormap
# @title: giflib-tools giftext color map
# @description: Uses giftext to dump the GIF color map from a fixture and verifies color table output is present.
# @timeout: 180
# @tags: usage, cli, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
giftext -c "$gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Global Color Map'
