#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-jpeg-subsampling-keyword-444
# @title: Pillow JPEG subsampling=0 (4:4:4) reports 4:4:4 on reload
# @description: Saves a JPEG with subsampling=0 (Pillow's 4:4:4 mode) and re-opens to confirm JpegImagePlugin.get_sampling returns 0, exercising the libjpeg-turbo no-chroma-subsampling encode/decode path.
# @timeout: 60
# @tags: usage, jpeg, python, subsampling
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image
from PIL.JpegImagePlugin import get_sampling

base = Path(sys.argv[1])
out = base / "ss444.jpg"
src = Image.new("RGB", (32, 24))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 3) & 255)
             for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=85, subsampling=0)

with Image.open(out) as im:
    im.load()
    sampling = get_sampling(im)
    assert sampling == 0, sampling
PY
