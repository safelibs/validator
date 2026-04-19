#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

w="$VALIDATOR_SOURCE_ROOT/examples/test.webp"; validator_require_file "$w"; webpinfo "$w" | tee "$tmpdir/i"; grep -Ei 'RIFF|Canvas|VP8' "$tmpdir/i"
