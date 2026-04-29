#!/usr/bin/env bash
# @testcase: usage-pngquant-compress-png
# @title: pngquant compress png
# @description: Runs pngquant compress png through libpng on a PNG fixture.
# @timeout: 180
# @tags: usage, image
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
pngquant --force --output "$tmpdir/out.png" 64 "$png"
file "$tmpdir/out.png"
