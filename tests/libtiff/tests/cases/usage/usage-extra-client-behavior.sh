#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
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
elif case_id == "usage-python3-pil-rgba-tiff":
    path = tmpdir / "rgba.tiff"
    Image.new("RGBA", (4, 3), (255, 0, 0, 128)).save(path)
    with Image.open(path) as im:
        im.load(); assert im.mode == "RGBA"; print("rgba", im.size)
elif case_id == "usage-python3-pil-float-tiff":
    path = tmpdir / "float.tiff"
    im = Image.new("F", (3, 2))
    im.putdata([1.25] * 6)
    im.save(path)
    with Image.open(path) as reopened:
        reopened.load(); assert reopened.mode == "F"; print("float", reopened.size)
elif case_id == "usage-python3-pil-tiff-to-jpeg":
    path = tmpdir / "out.jpg"
    with Image.open(fixture) as im:
        im.save(path, "JPEG")
    with Image.open(path) as im:
        assert im.format == "JPEG"; print("jpeg", im.size)
elif case_id == "usage-python3-pil-flip-topbottom-tiff":
    with Image.open(fixture) as im:
        out = im.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        assert out.size == im.size; print("flip", out.size)
elif case_id == "usage-python3-pil-split-bands-tiff":
    with Image.open(fixture) as im:
        bands = im.split()
        assert len(bands) == 3; print("bands", len(bands))
elif case_id == "usage-python3-pil-uncompressed-tiff":
    path = tmpdir / "raw.tiff"
    Image.new("RGB", (4, 4), "green").save(path, compression="raw")
    with Image.open(path) as im:
        im.load(); assert im.size == (4, 4); print("raw", im.size)
elif case_id == "usage-python3-pil-multiframe-count-tiff":
    path = tmpdir / "count.tiff"
    a = Image.new("RGB", (2, 2), "red")
    b = Image.new("RGB", (2, 2), "blue")
    c = Image.new("RGB", (2, 2), "green")
    a.save(path, save_all=True, append_images=[b, c])
    with Image.open(path) as im:
        assert sum(1 for _ in ImageSequence.Iterator(im)) == 3; print("frames", 3)
elif case_id == "usage-python3-pil-bilinear-resize-tiff":
    path = tmpdir / "bilinear.tiff"
    with Image.open(fixture) as im:
        out = im.resize((5, 5), resample=Image.Resampling.BILINEAR)
        out.save(path)
    with Image.open(path) as im:
        assert im.size == (5, 5); print("bilinear", im.size)
elif case_id == "usage-python3-pil-cmyk-tiff":
    path = tmpdir / "cmyk.tiff"
    Image.new("CMYK", (3, 2), (0, 128, 128, 0)).save(path)
    with Image.open(path) as im:
        im.load(); assert im.mode == "CMYK"; print("cmyk", im.size)
elif case_id == "usage-python3-pil-tiff-to-bmp":
    path = tmpdir / "out.bmp"
    with Image.open(fixture) as im:
        im.save(path, "BMP")
    with Image.open(path) as im:
        assert im.format == "BMP"; print("bmp", im.size)
else:
    raise SystemExit(f"unknown libtiff extra usage case: {case_id}")
PY
