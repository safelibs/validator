#!/usr/bin/env bash
# @testcase: usage-vips-r21-webpsave-effort-zero-vs-six-monotonic-size
# @title: vips webpsave effort=6 produces an output no larger than effort=0 at fixed Q
# @description: Encodes the same noisy RGB source to WEBP via vips webpsave at effort=0 and effort=6 with Q=80, asserting effort=6 output size is less than or equal to effort=0 — pinning libwebp's encoder-effort tradeoff through vips on Ubuntu 24.04.
# @timeout: 180
# @tags: usage, vips, webp, effort, r21
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/src.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (160, 120))
px = img.load()
for y in range(120):
    for x in range(160):
        px[x, y] = (x * 255 // 159, y * 255 // 119, ((x + y) * 255 // 278))
img.save(sys.argv[1], 'PNG')
PY

vips webpsave "$tmpdir/src.png" "$tmpdir/e0.webp" --Q 80 --effort 0
vips webpsave "$tmpdir/src.png" "$tmpdir/e6.webp" --Q 80 --effort 6

s0=$(stat -c '%s' "$tmpdir/e0.webp")
s6=$(stat -c '%s' "$tmpdir/e6.webp")
[[ "$s6" -le "$s0" ]] || { printf 'expected effort=6 (%s) <= effort=0 (%s)\n' "$s6" "$s0" >&2; exit 1; }
