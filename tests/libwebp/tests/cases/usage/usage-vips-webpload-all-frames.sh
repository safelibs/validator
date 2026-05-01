#!/usr/bin/env bash
# @testcase: usage-vips-webpload-all-frames
# @title: vips webpload n=-1 reads all animation frames
# @description: Builds a three-frame animated WebP with img2webp, then loads it through vips with [n=-1] (read every frame stacked vertically) and confirms the resulting page-stack height equals 3 * frame_height while page-height reports the per-frame height.
# @timeout: 240
# @tags: usage, webp, vips, animation
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build three solid-color 8x8 frames as PNGs.
python3 - <<'PY' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys
out = Path(sys.argv[1])
colors = [(220, 30, 30), (30, 220, 30), (30, 30, 220)]
for i, c in enumerate(colors):
    Image.new('RGB', (8, 8), c).save(out / f"f{i}.png", 'PNG')
PY

# Encode them as a single animated WebP via img2webp.
img2webp -loop 0 -d 80 "$tmpdir/f0.png" "$tmpdir/f1.png" "$tmpdir/f2.png" \
  -o "$tmpdir/anim.webp"
validator_require_file "$tmpdir/anim.webp"

file "$tmpdir/anim.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

# vips with n=-1 stacks every frame vertically. The resulting height
# must equal frames * page-height = 3 * 8 = 24 with width still 8.
vips copy "$tmpdir/anim.webp[n=-1]" "$tmpdir/all.v"
validator_require_file "$tmpdir/all.v"

width=$(vipsheader -f width "$tmpdir/all.v")
test "$width" = "8"
height=$(vipsheader -f height "$tmpdir/all.v")
test "$height" = "24"
page_height=$(vipsheader -f page-height "$tmpdir/all.v")
test "$page_height" = "8"
echo "all-frames width=$width height=$height page-height=$page_height"
