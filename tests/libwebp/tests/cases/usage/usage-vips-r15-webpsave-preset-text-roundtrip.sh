#!/usr/bin/env bash
# @testcase: usage-vips-r15-webpsave-preset-text-roundtrip
# @title: vips webpsave --preset text emits a structurally valid WebP at original geometry
# @description: Encodes a PPM through vips webpsave with --preset text and confirms the output is recognised as WebP and reloads with the original width and height, exercising the libwebp text-content tuning preset through vips.
# @timeout: 180
# @tags: usage, vips, webp, preset
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 56, 40
data = bytes([(((x * 7) ^ (y * 13)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/text.webp" --preset text --Q 80
file "$tmpdir/text.webp" | grep -q 'Web/P'

w=$(vipsheader -f width "$tmpdir/text.webp")
h=$(vipsheader -f height "$tmpdir/text.webp")
[[ "$w" -eq 56 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 40 ]] || { echo "height $h" >&2; exit 1; }
