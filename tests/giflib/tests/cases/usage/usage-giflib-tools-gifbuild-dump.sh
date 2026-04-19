#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SOURCE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/dump.txt"
grep -E 'screen|image|rgb' -i "$tmpdir/dump.txt" | head
