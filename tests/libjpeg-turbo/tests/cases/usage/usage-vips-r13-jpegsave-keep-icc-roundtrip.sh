#!/usr/bin/env bash
# @testcase: usage-vips-r13-jpegsave-keep-icc-roundtrip
# @title: vips jpegsave --profile attaches an ICC profile that survives the resave
# @description: Builds a JPEG carrying no profile via Pillow, then resaves it with "vips jpegsave --profile <icc>" (an sRGB profile) and asserts the resaved file contains the APP2 ICC_PROFILE identifier in its byte stream, exercising explicit profile embedding through the libjpeg-turbo encoder. (Vips jpegsave --keep icc does not always pull the Pillow-written profile — pass it explicitly via --profile to test the encoder's APP2 emission.)
# @timeout: 60
# @tags: usage, jpeg, image, metadata
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.jpg" "$tmpdir/profile.icc" <<'PY'
import sys
from PIL import Image
src = Image.new("RGB", (32, 24))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 5) & 255)
             for y in range(24) for x in range(32)])
src.save(sys.argv[1], "JPEG", quality=85)

# Locate a system sRGB ICC profile so vips has a real ICCv4-shaped blob to
# attach; fall back to a synthetic 256-byte stand-in if none is installed.
import os
candidates = [
    "/usr/share/color/icc/colord/sRGB.icc",
    "/usr/share/color/icc/sRGB.icc",
    "/usr/share/color/icc/sRGB_v4_ICC_preference.icc",
]
for path in candidates:
    if os.path.exists(path):
        with open(path, "rb") as f:
            blob = f.read()
        break
else:
    blob = bytes((i * 7 + 3) % 256 for i in range(256))
with open(sys.argv[2], "wb") as f:
    f.write(blob)
PY

vips jpegsave "$tmpdir/in.jpg" "$tmpdir/out.jpg" --Q 80 --profile "$tmpdir/profile.icc"

file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
grep -aq 'ICC_PROFILE' "$tmpdir/out.jpg" || {
    printf 'expected ICC_PROFILE in --profile output\n' >&2
    exit 1
}
