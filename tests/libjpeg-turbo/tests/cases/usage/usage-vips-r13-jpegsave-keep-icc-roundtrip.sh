#!/usr/bin/env bash
# @testcase: usage-vips-r13-jpegsave-keep-icc-roundtrip
# @title: vips jpegsave --keep icc preserves an embedded ICC profile through resave
# @description: Builds a JPEG carrying an ICC profile via Pillow, resaves it with vips jpegsave --keep icc, and asserts the resaved file still contains the APP2 ICC_PROFILE identifier in its byte stream, exercising the keep-flag-only-icc metadata pass-through.
# @timeout: 60
# @tags: usage, jpeg, image, metadata
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.jpg" <<'PY'
import sys
from PIL import Image
src = Image.new("RGB", (32, 24))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 5) & 255)
             for y in range(24) for x in range(32)])
icc = bytes((i * 7 + 3) % 256 for i in range(256))
src.save(sys.argv[1], "JPEG", quality=85, icc_profile=icc)
PY

# Confirm fixture has ICC.
grep -aq 'ICC_PROFILE' "$tmpdir/in.jpg"

vips jpegsave "$tmpdir/in.jpg" "$tmpdir/out.jpg" --Q 80 --keep icc

file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
grep -aq 'ICC_PROFILE' "$tmpdir/out.jpg" || {
    printf 'expected ICC_PROFILE in --keep icc output\n' >&2
    exit 1
}
