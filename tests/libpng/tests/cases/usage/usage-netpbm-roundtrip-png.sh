#!/usr/bin/env bash
# @testcase: usage-netpbm-roundtrip-png
# @title: netpbm roundtrip png
# @description: Runs netpbm roundtrip png through libpng on a PNG fixture.
# @timeout: 180
# @tags: usage, image
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
pngtopnm "$png" >"$tmpdir/out.pnm"
pnmtopng "$tmpdir/out.pnm" >"$tmpdir/round.png"
file "$tmpdir/round.png"
