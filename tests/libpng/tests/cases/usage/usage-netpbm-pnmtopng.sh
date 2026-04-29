#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng
# @title: netpbm pnmtopng
# @description: Runs netpbm pnmtopng through libpng on a PNG fixture.
# @timeout: 180
# @tags: usage, image
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
printf 'P3\n1 1\n255\n255 0 0\n' >"$tmpdir/in.pnm"
pnmtopng "$tmpdir/in.pnm" >"$tmpdir/out.png"
file "$tmpdir/out.png"
