#!/usr/bin/env bash
# @testcase: palette-fixture-handling
# @title: Palette PNG fixture handling
# @description: Checks palette color type handling on a PNGSuite palette fixture.
# @timeout: 120
# @tags: api, palette

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn3p08.png"; validator_require_file "$png"; file "$png"; pngfix --out="$tmpdir/out.png" "$png" >/dev/null; validator_require_file "$tmpdir/out.png"
