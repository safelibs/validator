#!/usr/bin/env bash
# @testcase: usage-pngquant-strip-png
# @title: pngquant strip png
# @description: Runs pngquant strip png through libpng on a PNG fixture.
# @timeout: 180
# @tags: usage, image
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
pngquant --force --strip --output "$tmpdir/out.png" "$png"
file "$tmpdir/out.png"
