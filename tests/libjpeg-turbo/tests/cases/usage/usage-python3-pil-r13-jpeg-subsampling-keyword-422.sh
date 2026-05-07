#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-jpeg-subsampling-keyword-422
# @title: Pillow JPEG subsampling=1 (4:2:2) reports 4:2:2 on reload
# @description: Saves a JPEG with subsampling=1 (Pillow's 4:2:2 mode) and re-opens to confirm JpegImagePlugin.get_sampling returns 1, exercising the libjpeg-turbo chroma 4:2:2 sampling factor encode/decode path.
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
out = base / "ss422.jpg"
src = Image.new("RGB", (32, 24))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 3) & 255)
             for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=80, subsampling=1)

with Image.open(out) as im:
    im.load()
    sampling = get_sampling(im)
    # 1 == 4:2:2 (horizontal-only subsampling).
    assert sampling == 1, sampling
PY
