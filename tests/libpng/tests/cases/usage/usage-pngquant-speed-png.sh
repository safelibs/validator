#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-png
# @title: pngquant speed png
# @description: Runs pngquant speed png through libpng on a PNG fixture.
# @timeout: 180
# @tags: usage, image
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
pngquant --force --speed 1 --output "$tmpdir/out.png" "$png"
validator_require_file "$tmpdir/out.png"
