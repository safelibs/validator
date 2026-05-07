#!/usr/bin/env bash
# @testcase: usage-pngquant-r12-skip-if-larger-keeps-original
# @title: pngquant --skip-if-larger does not write output when result would grow
# @description: Quantises a tiny 4x4 PNG with --skip-if-larger at a larger color count than necessary; the quantised output cannot be smaller than the trivially-paletted source, so pngquant must skip writing the output file with a non-zero exit status while leaving any pre-existing target untouched.
# @timeout: 60
# @tags: usage, image, png, skip-if-larger
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Tiny image where re-encoding to PNG cannot beat the original size.
python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 4, 4
b = bytes((10, 20, 30) * (W * H))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

# Pre-create a sentinel file at the output path; pngquant must not modify it
# when --skip-if-larger triggers.
printf 'sentinel\n' >"$tmpdir/out.png"
sentinel_before=$(sha256sum "$tmpdir/out.png" | awk '{print $1}')

set +e
pngquant --skip-if-larger --force --output "$tmpdir/out.png" 256 "$tmpdir/in.png"
rc=$?
set -e

# pngquant uses exit 98 to signal "skipped because larger".
[[ "$rc" -ne 0 ]] || { printf 'expected non-zero exit, got 0\n' >&2; exit 1; }

sentinel_after=$(sha256sum "$tmpdir/out.png" | awk '{print $1}')
[[ "$sentinel_before" == "$sentinel_after" ]] || {
  printf 'sentinel file was modified by pngquant despite skip-if-larger\n' >&2
  exit 1
}
