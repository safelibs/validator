#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-icc-profile-embedded
# @title: Pillow TIFF embedded ICC profile (tag 34675) roundtrip
# @description: Writes a TIFF with Pillow embedding a synthetic ICC profile blob via icc_profile, then verifies tiffinfo lists "ICC Profile" and Pillow re-exposes the exact bytes via info["icc_profile"] and tag 34675.
# @timeout: 180
# @tags: usage, image, python, metadata, color
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/icc.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

path = sys.argv[1]
size = (12, 8)
pixels = [
    ((x * 9) % 256, (y * 11) % 256, ((x + y) * 5) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)

# Synthetic but well-formed-enough ICC blob: minimum 128-byte header plus
# a tag table count of zero. libtiff/Pillow do not parse the contents,
# they only persist the bytes.
header = bytes(128)
tag_count = (0).to_bytes(4, "big")
icc = header + tag_count
assert len(icc) == 132
image.save(path, icc_profile=icc)
PY

validator_require_file "$img"

report="$tmpdir/info.txt"
tiffinfo "$img" >"$report"
validator_assert_contains "$report" "ICC Profile:"

python3 - <<'PY' "$img"
import sys
from PIL import Image

expected_len = 132
with Image.open(sys.argv[1]) as im:
    im.load()
    icc = im.info.get("icc_profile")
    assert icc is not None, "icc_profile missing from info"
    assert len(icc) == expected_len, ("len", len(icc))
    # Tag 34675 is the ICCProfile TIFF tag.
    assert 34675 in im.tag_v2, "ICCProfile tag (34675) missing"
    tag_blob = im.tag_v2[34675]
    if isinstance(tag_blob, tuple):
        tag_blob = bytes(tag_blob)
    assert len(tag_blob) == expected_len, ("tag len", len(tag_blob))
    assert bytes(tag_blob) == icc, "icc bytes diverge between info and tag_v2"
    assert im.size == (12, 8), im.size
    assert im.mode == "RGB", im.mode
    print("icc", len(icc), im.size)
PY
