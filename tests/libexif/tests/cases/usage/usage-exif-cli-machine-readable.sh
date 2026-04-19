#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    img="$VALIDATOR_SOURCE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
exif --machine-readable "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Make'