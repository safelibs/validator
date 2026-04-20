#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/in.pam"
pamflip -r90 "$tmpdir/in.pam" >"$tmpdir/rotated.pam"
pnmtopng "$tmpdir/rotated.pam" >"$tmpdir/out.png"

file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
pngtopam "$tmpdir/out.png" | pamfile - | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'
