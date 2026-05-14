#!/usr/bin/env bash
# @testcase: usage-vips-r17-webpsave-buffer-lossless-magic-riff
# @title: vips webpsave lossless=true output begins with RIFF/WEBP container magic
# @description: Encodes a small PPM to WEBP via vips webpsave with lossless=true, then asserts the resulting file begins with the RIFF...WEBP container magic and that vipsheader can re-parse the file's width and height.
# @timeout: 120
# @tags: usage, vips, webp, lossless, magic
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 64, 48
data = bytes([(((x * 5) ^ (y * 3)) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/out.webp" --lossless true
validator_require_file "$tmpdir/out.webp"

# RIFF<size>WEBP at bytes 0..11
head -c 4 "$tmpdir/out.webp" | od -An -c | tr -d ' \n' | grep -Fq 'RIFF'
head -c 12 "$tmpdir/out.webp" | tail -c 4 | od -An -c | tr -d ' \n' | grep -Fq 'WEBP'

w_out=$(vipsheader -f width "$tmpdir/out.webp")
h_out=$(vipsheader -f height "$tmpdir/out.webp")
[[ "$w_out" == "64" && "$h_out" == "48" ]] || {
    printf 'unexpected dims %sx%s\n' "$w_out" "$h_out" >&2
    exit 1
}
