#!/usr/bin/env bash
# @testcase: usage-netpbm-pngtopam
# @title: netpbm pngtopam
# @description: Runs netpbm pngtopam through libpng on a PNG fixture.
# @timeout: 180
# @tags: usage, image
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
pngtopam "$png" >"$tmpdir/out.pam"
head -n 4 "$tmpdir/out.pam"
