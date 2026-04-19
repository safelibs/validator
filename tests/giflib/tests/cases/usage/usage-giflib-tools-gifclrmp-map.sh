#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SOURCE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifclrmp "$gif" | tee "$tmpdir/out"
grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
