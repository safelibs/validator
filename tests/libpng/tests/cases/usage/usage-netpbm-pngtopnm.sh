#!/usr/bin/env bash
# @testcase: usage-netpbm-pngtopnm
# @title: netpbm pngtopnm
# @description: Runs netpbm pngtopnm through libpng on a PNG fixture.
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
head -n 2 "$tmpdir/out.pnm"
