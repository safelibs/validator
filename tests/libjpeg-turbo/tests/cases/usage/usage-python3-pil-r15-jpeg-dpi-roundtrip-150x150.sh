#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-jpeg-dpi-roundtrip-150x150
# @title: Pillow JPEG save dpi=(150, 150) round-trips through im.info["dpi"]
# @description: Saves an RGB JPEG via Pillow with dpi=(150, 150) and re-opens to confirm im.info["dpi"] returns a 2-tuple whose values are within 1 unit of (150, 150), exercising libjpeg-turbo's JFIF density field writer/reader through Pillow.
# @timeout: 60
# @tags: usage, jpeg, python, dpi
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
out = base / "dpi.jpg"
src = Image.new("RGB", (24, 18), (200, 60, 90))
src.save(out, "JPEG", quality=85, dpi=(150, 150))

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    dpi = im.info.get("dpi")
    assert dpi is not None, "missing dpi info"
    assert len(dpi) == 2, dpi
    dx, dy = float(dpi[0]), float(dpi[1])
    assert abs(dx - 150) <= 1.0, dpi
    assert abs(dy - 150) <= 1.0, dpi
PY
