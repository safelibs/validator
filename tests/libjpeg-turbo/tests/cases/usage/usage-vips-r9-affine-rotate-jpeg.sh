#!/usr/bin/env bash
# @testcase: usage-vips-r9-affine-rotate-jpeg
# @title: vips rot 90 swaps JPEG dimensions
# @description: Applies vips rot d90 to a non-square JPEG and verifies the resulting JPEG header reports dimensions swapped relative to the source.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 6, 3
data = bytes([255, 0, 0] * (w * h))
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips rot "$tmpdir/in.jpg" "$tmpdir/out.jpg" d90

w_in=$(vipsheader -f width "$tmpdir/in.jpg")
h_in=$(vipsheader -f height "$tmpdir/in.jpg")
w_out=$(vipsheader -f width "$tmpdir/out.jpg")
h_out=$(vipsheader -f height "$tmpdir/out.jpg")

[[ "$w_in" == "6" && "$h_in" == "3" ]]
[[ "$w_out" == "$h_in" && "$h_out" == "$w_in" ]] || {
  printf 'expected swapped dims, got %sx%s -> %sx%s\n' "$w_in" "$h_in" "$w_out" "$h_out" >&2
  exit 1
}
