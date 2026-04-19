#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SOURCE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
validator_require_file "$tmpdir/out.rgb"
wc -c "$tmpdir/out.rgb"
