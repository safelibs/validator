#!/usr/bin/env bash
# @testcase: usage-vips-r17-bandjoin-two-grayscale-jpegs
# @title: vips bandjoin two single-band JPEGs yields a 2-band image
# @description: Encodes two 16x12 single-band PGMs as grayscale JPEGs then runs vips bandjoin on the pair, asserting the resulting image has 2 bands and the original dimensions reported by vipsheader, exercising libjpeg-turbo grayscale decode followed by vips bandjoin (distinct from the r11 RGB-bandjoin test).
# @timeout: 180
# @tags: usage, vips, jpeg, bandjoin
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/a.pgm" "$tmpdir/b.pgm"
import sys
W, H = 16, 12
for path, seed in ((sys.argv[1], 3), (sys.argv[2], 7)):
    data = bytes([((x * seed) ^ (y * seed * 2)) & 0xff
                  for y in range(H) for x in range(W)])
    open(path, 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/a.pgm" "$tmpdir/a.jpg" --Q 85
vips jpegsave "$tmpdir/b.pgm" "$tmpdir/b.jpg" --Q 85
vips bandjoin "$tmpdir/a.jpg" "$tmpdir/b.jpg" "$tmpdir/out.v"

vipsheader "$tmpdir/out.v" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '16x12'
validator_assert_contains "$tmpdir/hdr" '2 bands'
