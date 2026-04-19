#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SOURCE_ROOT/pic/treescap-interlaced.gif"; expected="$VALIDATOR_SOURCE_ROOT/tests/treescap-interlaced.rgb"; validator_require_file "$gif"; validator_require_file "$expected"; gif2rgb -o "$tmpdir/out.rgb" "$gif"; cmp "$expected" "$tmpdir/out.rgb"
