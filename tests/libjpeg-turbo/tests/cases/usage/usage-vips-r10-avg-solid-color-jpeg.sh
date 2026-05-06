#!/usr/bin/env bash
# @testcase: usage-vips-r10-avg-solid-color-jpeg
# @title: vips avg of a solid-color JPEG approximates the source value
# @description: Encodes a solid mid-gray (128) JPEG at high quality, then computes the mean pixel value via vips avg. The mean must be within 2 of 128 once decoded back through libjpeg-turbo.
# @timeout: 180
# @tags: usage, jpeg, image, statistics
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 64, 64
data = bytes([128] * (w * h * 3))
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/gray.jpg" --Q 95

mean=$(vips avg "$tmpdir/gray.jpg")
echo "mean=$mean"

python3 - "$mean" <<'PY'
import sys
m = float(sys.argv[1])
assert 126.0 <= m <= 130.0, f"mean {m} not within tolerance of 128"
print("avg-ok", m)
PY
