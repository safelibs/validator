#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SOURCE_ROOT/test/test-suite/images/sample.png"; validator_require_file "$img"; vipsheader -a "$img" | tee "$tmpdir/h"; grep -E 'width|height|bands' "$tmpdir/h"
