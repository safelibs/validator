#!/usr/bin/env bash
# @testcase: usage-pngquant-default-fs8-suffix-png
# @title: pngquant default output filename uses -fs8.png suffix
# @description: Copies basn2c08.png into a temp directory as input.png, runs pngquant with --force but no --output / --ext (default behaviour), and confirms pngquant produced an output named input-fs8.png in the same directory while the original input.png is still present and the input-or8.png variant (used only with --nofs) is absent.
# @timeout: 180
# @tags: usage, image, png, output, pngquant
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

cp "$png" "$tmpdir/input.png"

# Run pngquant in tmpdir with default output naming. With Floyd-Steinberg
# enabled (the default), pngquant emits "<basename>-fs8.png".
(cd "$tmpdir" && pngquant --force 16 input.png)

ls -la "$tmpdir" | tee "$tmpdir/listing"
validator_assert_contains "$tmpdir/listing" 'input-fs8.png'

test -s "$tmpdir/input.png"
test -s "$tmpdir/input-fs8.png"
# --nofs would have produced -or8.png; we did not pass --nofs.
test ! -e "$tmpdir/input-or8.png"

file "$tmpdir/input-fs8.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Verify the PNG magic on the default-suffix output.
python3 - "$tmpdir/input-fs8.png" <<'PY'
import sys

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
if data[:8] != sig:
    raise SystemExit(f'bad PNG signature: {data[:8]!r}')
print('PNG signature OK')
PY

# Pixel dimensions must survive.
pngtopam "$tmpdir/input-fs8.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'
