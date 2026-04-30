#!/usr/bin/env bash
# @testcase: usage-pngquant-stdout-png
# @title: pngquant writes PNG to stdout
# @description: Runs pngquant with --output - so the optimized PNG is emitted on stdout, then validates the captured bytes.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --force --output - 256 "$png" >"$tmpdir/out.png"
test -s "$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
PY
