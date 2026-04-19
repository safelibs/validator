#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SOURCE_ROOT/pic/treescap.gif"; validator_require_file "$gif"; head -c 32 "$gif" >"$tmpdir/bad.gif"; if giftext "$tmpdir/bad.gif" >"$tmpdir/log" 2>&1; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
