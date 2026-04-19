#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

validator_require_file "$VALIDATOR_SOURCE_ROOT/examples/csvtest.c"; validator_require_file "$VALIDATOR_SOURCE_ROOT/tests/test_01.csv"; gcc "$VALIDATOR_SOURCE_ROOT/examples/csvtest.c" -o "$tmpdir/csvtest" -lcsv; "$tmpdir/csvtest" <"$VALIDATOR_SOURCE_ROOT/tests/test_01.csv" | tee "$tmpdir/out"; grep ',' "$tmpdir/out"
