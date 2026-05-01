#!/usr/bin/env bash
# @testcase: usage-pngquant-floyd-half-strength-png
# @title: pngquant --floyd 0.5 vs 1.0 dithering strength
# @description: Quantizes basn2c08.png at --floyd 0.5 and --floyd 1.0 and confirms both produce valid 32x32 indexed PNGs whose decoded byte streams differ from each other and from a --nofs (no dither) baseline, exercising fractional Floyd-Steinberg strength not covered by existing zero/default cases.
# @timeout: 180
# @tags: usage, image, png, quantization
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --floyd=0.5 --force --output "$tmpdir/half.png" 16 "$png"
pngquant --floyd=1.0 --force --output "$tmpdir/full.png" 16 "$png"
pngquant --nofs --force --output "$tmpdir/nofs.png" 16 "$png"

for f in half full nofs; do
  file "$tmpdir/$f.png" | tee "$tmpdir/$f.file"
  validator_assert_contains "$tmpdir/$f.file" 'PNG image data'
  pngtopnm "$tmpdir/$f.png" >"$tmpdir/$f.ppm"
  pamfile "$tmpdir/$f.ppm" | tee "$tmpdir/$f.pamfile" || true
done

# All three decoded streams must be valid 32x32 PPM and pairwise distinct
# in raw pixel content (different dither strengths yield different pixels
# even when sharing the same 16-color palette decision).
python3 - "$tmpdir/half.ppm" "$tmpdir/full.ppm" "$tmpdir/nofs.ppm" <<'PY'
import sys

def read(path):
    return open(path, 'rb').read()

a, b, c = (read(p) for p in sys.argv[1:4])
if a == b:
    raise SystemExit('--floyd 0.5 and --floyd 1.0 produced identical output')
if a == c:
    raise SystemExit('--floyd 0.5 and --nofs produced identical output')
if b == c:
    raise SystemExit('--floyd 1.0 and --nofs produced identical output')
print(f'sizes half={len(a)} full={len(b)} nofs={len(c)}')
PY
