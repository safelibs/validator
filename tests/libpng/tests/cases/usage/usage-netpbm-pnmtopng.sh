#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    png="$VALIDATOR_SOURCE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
printf 'P3\n1 1\n255\n255 0 0\n' >"$tmpdir/in.pnm"
pnmtopng "$tmpdir/in.pnm" >"$tmpdir/out.png"
file "$tmpdir/out.png"