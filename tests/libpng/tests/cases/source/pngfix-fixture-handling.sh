#!/usr/bin/env bash
# @testcase: pngfix-fixture-handling
# @title: pngfix fixture handling
# @description: Runs pngfix against a checked-in PNGSuite fixture and validates output.
# @timeout: 120
# @tags: cli, media

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"; validator_require_file "$png"; pngfix --out="$tmpdir/fixed.png" "$png" | tee "$tmpdir/log"; validator_require_file "$tmpdir/fixed.png"; file "$tmpdir/fixed.png"
