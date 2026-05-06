#!/usr/bin/env bash
# @testcase: usage-vips-r11-bandjoin-rgb-jpeg
# @title: vips bandjoin recombines three single-band channels into an RGB JPEG
# @description: Splits a JPEG into its three colour bands with extract_band, then bandjoins them back into a 3-band image saved as JPEG, asserting the joined output has 3 bands and the original geometry via vipsheader.
# @timeout: 90
# @tags: usage, jpeg, image, bandjoin
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 40, 30
data = bytes([(i * 7) & 0xFF for i in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips extract_band "$tmpdir/in.jpg" "$tmpdir/r.v" 0 --n 1
vips extract_band "$tmpdir/in.jpg" "$tmpdir/g.v" 1 --n 1
vips extract_band "$tmpdir/in.jpg" "$tmpdir/b.v" 2 --n 1
vips bandjoin "$tmpdir/r.v $tmpdir/g.v $tmpdir/b.v" "$tmpdir/out.jpg"

vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 40'
validator_assert_contains "$tmpdir/hdr" 'height: 30'
validator_assert_contains "$tmpdir/hdr" 'bands: 3'
