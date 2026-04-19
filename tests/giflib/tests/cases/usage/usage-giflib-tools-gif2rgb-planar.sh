#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SOURCE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gif2rgb -o "$tmpdir/planes" "$gif"
validator_require_file "$tmpdir/planes.R"
validator_require_file "$tmpdir/planes.G"
validator_require_file "$tmpdir/planes.B"
wc -c "$tmpdir/planes.R" "$tmpdir/planes.G" "$tmpdir/planes.B"
