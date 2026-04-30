#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-quality-vs-high
# @title: ffmpeg WebP -q:v low vs high size monotonic
# @description: Encodes the same PPM source via ffmpeg libwebp at low and high -q:v values and asserts the higher quality output is strictly larger.
# @timeout: 180
# @tags: usage, webp, encode
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
import random

random.seed(0xC0FFEE)
w, h = 32, 24
data = bytearray()
for _ in range(w * h):
    data.append(random.randint(0, 255))
    data.append(random.randint(0, 255))
    data.append(random.randint(0, 255))
header = f"P6\n{w} {h}\n255\n".encode()
Path(sys.argv[1]).write_bytes(header + bytes(data))
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -compression_level 4 -q:v 10 "$tmpdir/low.webp"
ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -compression_level 4 -q:v 95 "$tmpdir/high.webp"

validator_require_file "$tmpdir/low.webp"
validator_require_file "$tmpdir/high.webp"
file "$tmpdir/low.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

low_size=$(wc -c <"$tmpdir/low.webp")
high_size=$(wc -c <"$tmpdir/high.webp")
printf 'low=%s high=%s\n' "$low_size" "$high_size"
test "$high_size" -gt "$low_size"
