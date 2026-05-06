#!/usr/bin/env bash
# @testcase: usage-vips-r9-jpegsave-trellis-quant
# @title: vips jpegsave with trellis quantisation produces valid JPEG
# @description: Encodes a small image via vips jpegsave with --trellis-quant and confirms the output JPEG decodes back through vipsheader with the expected dimensions.
# @timeout: 180
# @tags: usage, jpeg, image, encode
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 16, 16
data = bytes([(x * 8) & 0xFF for x in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/out.jpg" --trellis-quant

[[ -s "$tmpdir/out.jpg" ]]
# Verify output is recognized as JPEG by readable header.
hdr=$(vipsheader "$tmpdir/out.jpg")
echo "$hdr" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '16x16'
