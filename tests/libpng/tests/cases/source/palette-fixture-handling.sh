#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SOURCE_ROOT/contrib/pngsuite/basn3p08.png"; validator_require_file "$png"; file "$png"; pngfix --out="$tmpdir/out.png" "$png" >/dev/null; validator_require_file "$tmpdir/out.png"
