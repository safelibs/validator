#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SOURCE_ROOT/test/test-suite/images/sample.jpg"; validator_require_file "$img"; vips copy "$img" "$tmpdir/out.png"; vipsheader "$tmpdir/out.png" | tee "$tmpdir/h"; grep -E '[0-9]+x[0-9]+' "$tmpdir/h"
