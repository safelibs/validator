#!/usr/bin/env bash
# @testcase: usage-vips-r20-flatten-rgba-to-jpeg-three-bands
# @title: vips flatten on a 4-band PAM saved as JPEG yields a 3-band JPEG
# @description: Builds a 24x16 PAM with TUPLTYPE RGB_ALPHA, runs vips flatten to composite alpha against white, and saves the result as JPEG; opens the output via vipsheader -f bands and asserts the band count is exactly 3, exercising libjpeg-turbo's RGB encode path after vips' alpha-flatten conversion.
# @timeout: 180
# @tags: usage, vips, jpeg, flatten, alpha, r20
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
W, H = 24, 16
hdr = f'P7\nWIDTH {W}\nHEIGHT {H}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n'.encode()
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes(((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff, 128))
open(sys.argv[1], 'wb').write(hdr + body)
PY

vips flatten "$tmpdir/in.pam" "$tmpdir/out.jpg"
validator_require_file "$tmpdir/out.jpg"
bands=$(vipsheader -f bands "$tmpdir/out.jpg")
[[ "$bands" == "3" ]] || { printf 'expected 3 bands, got %s\n' "$bands" >&2; exit 1; }
