#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SOURCE_ROOT/pic/treescap.gif"; validator_require_file "$gif"; giftext "$gif" | tee "$tmpdir/out.txt"; grep -Ei 'screen|image|gif' "$tmpdir/out.txt" >/dev/null
