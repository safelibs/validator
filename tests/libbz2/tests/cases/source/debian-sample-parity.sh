#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for s in sample1 sample2 sample3; do validator_require_file "$VALIDATOR_SAMPLE_ROOT/$s.bz2"; validator_require_file "$VALIDATOR_SAMPLE_ROOT/$s.ref"; bunzip2 -c "$VALIDATOR_SAMPLE_ROOT/$s.bz2" >"$tmpdir/$s.out"; cmp "$VALIDATOR_SAMPLE_ROOT/$s.ref" "$tmpdir/$s.out"; wc -c "$tmpdir/$s.out"; done
