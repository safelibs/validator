#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from io import BytesIO
from pathlib import Path
from PIL import Image
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

if case_id == "usage-python3-pil-mirror-left-right-tiff":
    with Image.open(fixture) as im:
        out = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        assert out.size == im.size
        print("mirror", out.size)
elif case_id == "usage-python3-pil-bytesio-open-tiff":
    payload = Path(fixture).read_bytes()
    with Image.open(BytesIO(payload)) as im:
        im.load()
        assert im.size[0] > 0 and im.size[1] > 0
        print("bytesio", im.size)
elif case_id == "usage-python3-pil-point-shift-tiff":
    path = tmpdir / "point.tiff"
    with Image.open(fixture) as im:
        out = im.point(lambda value: min(255, value + 5))
        out.save(path)
    with Image.open(path) as im:
        assert im.size[0] > 0 and im.size[1] > 0
        print("point", im.size)
elif case_id == "usage-python3-pil-paste-region-tiff":
    path = tmpdir / "paste.tiff"
    canvas = Image.new("RGB", (8, 8), "black")
    with Image.open(fixture) as im:
        canvas.paste(im, (1, 1))
    canvas.save(path)
    with Image.open(path) as im:
        assert im.size == (8, 8)
        print("paste", im.size)
elif case_id == "usage-python3-pil-split-merge-tiff":
    path = tmpdir / "merge.tiff"
    with Image.open(fixture) as im:
        bands = im.split()
        merged = Image.merge(im.mode, bands)
        merged.save(path)
    with Image.open(path) as im:
        assert im.size[0] > 0 and im.size[1] > 0
        print("merge", im.size)
elif case_id == "usage-python3-pil-rotate-270-tiff":
    with Image.open(fixture) as im:
        out = im.transpose(Image.Transpose.ROTATE_270)
        assert out.size == (im.size[1], im.size[0])
        print("rotate270", out.size)
elif case_id == "usage-python3-pil-resize-nearest-tiff":
    path = tmpdir / "nearest.tiff"
    with Image.open(fixture) as im:
        out = im.resize((5, 5), resample=Image.Resampling.NEAREST)
        out.save(path)
    with Image.open(path) as im:
        assert im.size == (5, 5)
        print("nearest", im.size)
elif case_id == "usage-python3-pil-getbbox-tiff":
    with Image.open(fixture) as im:
        box = im.getbbox()
        assert box is not None and len(box) == 4
        print("bbox", box)
elif case_id == "usage-python3-pil-la-mode-tiff":
    path = tmpdir / "la.tiff"
    Image.new("LA", (4, 3), (120, 200)).save(path)
    with Image.open(path) as im:
        im.load()
        assert im.mode == "LA"
        print("la", im.size)
elif case_id == "usage-python3-pil-save-memory-tiff":
    with Image.open(fixture) as im:
        handle = BytesIO()
        im.save(handle, "TIFF")
    payload = handle.getvalue()
    assert len(payload) > 0
    with Image.open(BytesIO(payload)) as im:
        assert im.size[0] > 0 and im.size[1] > 0
        print("memory-save", im.size)
else:
    raise SystemExit(f"unknown libtiff additional usage case: {case_id}")
PY
