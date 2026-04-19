#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

t="$VALIDATOR_SOURCE_ROOT/test/images/rgb-3c-8b.tiff"; validator_require_file "$t"; tiffinfo "$t" | tee "$tmpdir/info"; grep -Ei 'Image Width|Bits/Sample' "$tmpdir/info"
