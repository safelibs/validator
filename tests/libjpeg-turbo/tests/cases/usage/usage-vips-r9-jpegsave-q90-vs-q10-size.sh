#!/usr/bin/env bash
# @testcase: usage-vips-r9-jpegsave-q90-vs-q10-size
# @title: vips jpegsave q=90 larger than q=10
# @description: Encodes the same source image with vips jpegsave at Q=10 and Q=90 and verifies the higher-quality output is strictly larger on disk.
# @timeout: 180
# @tags: usage, jpeg, image, quality
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a noisy ppm so jpeg quality difference is significant.
python3 - "$tmpdir/in.ppm" <<'PY'
import random, sys
random.seed(7)
w, h = 64, 64
header = f"P6\n{w} {h}\n255\n".encode()
body = bytes(random.randint(0, 255) for _ in range(w * h * 3))
open(sys.argv[1], "wb").write(header + body)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/q10.jpg" --Q 10
vips jpegsave "$tmpdir/in.ppm" "$tmpdir/q90.jpg" --Q 90

s10=$(stat -c '%s' "$tmpdir/q10.jpg")
s90=$(stat -c '%s' "$tmpdir/q90.jpg")
[[ "$s90" -gt "$s10" ]] || {
  printf 'expected q90>q10, got %s vs %s\n' "$s90" "$s10" >&2
  exit 1
}
