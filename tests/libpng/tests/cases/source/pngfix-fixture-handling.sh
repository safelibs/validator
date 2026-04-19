#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SOURCE_ROOT/contrib/pngsuite/basn2c08.png"; validator_require_file "$png"; pngfix --out="$tmpdir/fixed.png" "$png" | tee "$tmpdir/log"; validator_require_file "$tmpdir/fixed.png"; file "$tmpdir/fixed.png"
