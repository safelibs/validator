#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"; expected="$VALIDATOR_SAMPLE_ROOT/tests/fire.rgb"; validator_require_file "$gif"; validator_require_file "$expected"; gif2rgb -1 -o "$tmpdir/fire.rgb" "$gif"; cmp "$expected" "$tmpdir/fire.rgb"; wc -c "$tmpdir/fire.rgb"
