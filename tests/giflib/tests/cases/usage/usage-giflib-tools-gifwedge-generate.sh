#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SOURCE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifwedge >"$tmpdir/wedge.gif"
giftext "$tmpdir/wedge.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'