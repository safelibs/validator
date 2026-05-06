#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-jpeg-jfif-version
# @title: Pillow exposes JFIF version on JPEG load
# @description: Saves a JPEG with Pillow then reopens and asserts info['jfif'], info['jfif_version'], and info['jfif_unit'] are populated as expected for a JFIF/APP0 marker.
# @timeout: 180
# @tags: usage, jpeg, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

out = sys.argv[1] + "/jfif.jpg"
src = Image.new("RGB", (24, 16))
src.putdata([((x * 9) & 255, (y * 11) & 255, ((x ^ y) * 5) & 255) for y in range(16) for x in range(24)])
src.save(out, "JPEG", quality=85)

with Image.open(out) as im:
    im.load()
    info = im.info
    assert "jfif" in info, sorted(info.keys())
    assert info["jfif_version"] == (1, 1) or info["jfif_version"] == (1, 2), info["jfif_version"]
    # jfif_unit: 0=no units, 1=dpi, 2=dpcm.
    assert info["jfif_unit"] in (0, 1, 2), info["jfif_unit"]
    assert "jfif_density" in info, sorted(info.keys())
    print("jfif", info["jfif_version"], info["jfif_unit"], info["jfif_density"])
PY
