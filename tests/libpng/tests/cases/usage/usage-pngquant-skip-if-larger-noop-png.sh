#!/usr/bin/env bash
# @testcase: usage-pngquant-skip-if-larger-noop-png
# @title: pngquant --skip-if-larger on a compressible 4x4 PNG
# @description: Builds a 4x4 high-entropy PNG that pngquant is unlikely to shrink and runs --skip-if-larger; either the quantised output is a smaller PNG (rc=0) or pngquant declines via rc=98/99 without writing the file.
# @timeout: 120
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-skip-if-larger-noop-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a 4x4 PPM with 16 distinct colours, hand off to pnmtopng -> small PNG.
python3 - "$tmpdir/seed.ppm" <<'PY'
import sys
with open(sys.argv[1], 'w', encoding='ascii') as h:
    h.write('P3\n4 4\n255\n')
    for i in range(16):
        r = (i * 31) % 256
        g = (i * 67) % 256
        b = (i * 113) % 256
        h.write(f'{r} {g} {b} ')
PY
pnmtopng "$tmpdir/seed.ppm" >"$tmpdir/seed.png"
file "$tmpdir/seed.png" | tee "$tmpdir/seedfile"
validator_assert_contains "$tmpdir/seedfile" 'PNG image data'

set +e
pngquant --skip-if-larger --force --output "$tmpdir/out.png" 256 "$tmpdir/seed.png"
rc=$?
set -e
printf 'pngquant exit=%s\n' "$rc"

case "$rc" in
  0)
    file "$tmpdir/out.png" | tee "$tmpdir/file"
    validator_assert_contains "$tmpdir/file" 'PNG image data'
    seed_size=$(stat -c '%s' "$tmpdir/seed.png")
    out_size=$(stat -c '%s' "$tmpdir/out.png")
    if (( out_size > seed_size )); then
      printf 'expected --skip-if-larger to refuse larger output, but out=%s > seed=%s\n' "$out_size" "$seed_size" >&2
      exit 1
    fi
    ;;
  98|99)
    test ! -e "$tmpdir/out.png"
    printf 'pngquant declined to write a larger output (rc=%s)\n' "$rc"
    ;;
  *)
    printf 'unexpected pngquant exit status: %s\n' "$rc" >&2
    exit 1
    ;;
esac
