#!/usr/bin/env bash
# @testcase: usage-pngquant-r11-quality-99-100-exit-99
# @title: pngquant --quality=99-100 exits 99 on noisy input
# @description: Quantises a 64x64 random-noise PNG with --quality=99-100 limited to 4 colors. The minimum quality cannot be met at that palette size, so pngquant must exit with status 99 and not write the output file.
# @timeout: 120
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys, random
random.seed(7)
W, H = 64, 64
b = bytearray()
for _ in range(W * H):
    b += bytes((random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

set +e
pngquant --quality=99-100 --force --output "$tmpdir/out.png" 4 "$tmpdir/in.png"
rc=$?
set -e

[[ "$rc" -eq 99 ]] || { printf 'expected exit 99, got %s\n' "$rc" >&2; exit 1; }
# pngquant must not have written the output file when the quality minimum is unmet.
[[ ! -f "$tmpdir/out.png" ]] || { printf 'unexpected output file written\n' >&2; exit 1; }
