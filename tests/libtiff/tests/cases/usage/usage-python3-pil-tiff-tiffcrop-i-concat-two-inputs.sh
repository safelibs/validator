#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcrop-i-concat-two-inputs
# @title: Pillow TIFF tiffcrop -i with two single-page inputs
# @description: Writes two single-page Pillow TIFFs of identical geometry, runs tiffcrop -i (ignore read errors) with both as sources to produce a single multi-frame output, and verifies the destination opens as a 2-frame TIFF whose per-page solid colors round-trip via Pillow seek().
# @timeout: 180
# @tags: usage, image, python, cli, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

a="$tmpdir/a.tiff"
b="$tmpdir/b.tiff"
out="$tmpdir/concat.tiff"

python3 - <<'PY' "$a" "$b"
import sys
from PIL import Image

a_path, b_path = sys.argv[1], sys.argv[2]
Image.new("RGB", (16, 12), (210, 40, 40)).save(a_path)
Image.new("RGB", (16, 12), (40, 210, 40)).save(b_path)
PY

validator_require_file "$a"
validator_require_file "$b"

tiffcrop -i "$a" "$b" "$out"
validator_require_file "$out"

python3 - <<'PY' "$out"
import sys
from PIL import Image

expected = [(210, 40, 40), (40, 210, 40)]
with Image.open(sys.argv[1]) as im:
    n = getattr(im, "n_frames", 1)
    assert n == 2, ("frames", n)
    for i, want in enumerate(expected):
        im.seek(i)
        im.load()
        assert im.size == (16, 12), (i, im.size)
        assert im.mode == "RGB", (i, im.mode)
        got = im.getpixel((8, 6))
        assert got == want, (i, got, want)
    print("concat2", n)
PY
