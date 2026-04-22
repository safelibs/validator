#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

if case_id == "usage-python3-pil-grayscale-tiff":
    path = tmpdir / "gray.tiff"
    Image.new("L", (6, 4), 128).save(path)
    with Image.open(path) as im:
        im.load(); assert im.mode == "L" and im.size == (6, 4); print("gray", im.mode, im.size)
elif case_id == "usage-python3-pil-bilevel-tiff":
    path = tmpdir / "onebit.tiff"
    Image.new("1", (6, 4), 1).save(path)
    with Image.open(path) as im:
        im.load(); assert im.mode == "1"; print("onebit", im.size)
elif case_id == "usage-python3-pil-packbits-tiff":
    path = tmpdir / "packbits.tiff"
    Image.new("RGB", (5, 5), "purple").save(path, compression="packbits")
    with Image.open(path) as im:
        im.load(); assert im.size == (5, 5); print("packbits", im.size)
elif case_id == "usage-python3-pil-rotate-tiff":
    with Image.open(fixture) as im:
        out = im.transpose(Image.Transpose.ROTATE_90)
        assert out.size == (im.size[1], im.size[0]); print("rotate", out.size)
elif case_id == "usage-python3-pil-transpose-tiff":
    with Image.open(fixture) as im:
        out = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        assert out.size == im.size; print("transpose", out.size)
elif case_id == "usage-python3-pil-resize-tiff":
    path = tmpdir / "resize.tiff"
    with Image.open(fixture) as im:
        out = im.resize((4, 4))
        out.save(path)
    with Image.open(path) as im:
        assert im.size == (4, 4); print("resize", im.size)
elif case_id == "usage-python3-pil-palette-tiff":
    path = tmpdir / "palette.tiff"
    im = Image.new("P", (4, 4))
    im.putpalette([0, 0, 0, 255, 0, 0] + [0, 0, 0] * 254)
    im.save(path)
    with Image.open(path) as reopened:
        reopened.load(); assert reopened.mode in {"P", "RGB"}; print("palette", reopened.mode)
elif case_id == "usage-python3-pil-icc-info-tiff":
    with Image.open(fixture) as im:
        print("tags", len(im.tag_v2), "info", sorted(im.info)[:3])
        assert len(im.tag_v2) > 0
elif case_id == "usage-python3-pil-multiframe-seek-tiff":
    path = tmpdir / "multi.tiff"
    a = Image.new("RGB", (2, 2), "red")
    b = Image.new("RGB", (2, 2), "blue")
    a.save(path, save_all=True, append_images=[b])
    with Image.open(path) as im:
        im.seek(1); assert im.size == (2, 2); print("frame", im.tell())
elif case_id == "usage-python3-pil-tiff-to-png":
    path = tmpdir / "out.png"
    with Image.open(fixture) as im:
        im.save(path, "PNG")
    with Image.open(path) as im:
        assert im.format == "PNG"; print("png", im.size)
else:
    raise SystemExit(f"unknown libtiff extra usage case: {case_id}")
PY
