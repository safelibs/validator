#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/test-suite/images/sample.png"; validator_require_file "$img"; vips copy "$img" "$tmpdir/out.png"; vipsheader -f width "$tmpdir/out.png" | tee "$tmpdir/width"; vipsheader -f height "$tmpdir/out.png" | tee "$tmpdir/height"; grep -E '^[1-9][0-9]*$' "$tmpdir/width"; grep -E '^[1-9][0-9]*$' "$tmpdir/height"
