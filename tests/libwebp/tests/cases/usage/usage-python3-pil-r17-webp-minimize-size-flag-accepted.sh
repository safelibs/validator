#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-webp-minimize-size-flag-accepted
# @title: Pillow WEBP save accepts minimize_size=True and round-trips dims and mode
# @description: Saves a small RGB image with Pillow's WEBP minimize_size=True flag, re-opens the file, and asserts the round-trip preserves mode and dimensions while producing a non-empty WebP payload.
# @timeout: 60
# @tags: usage, python3-pil, webp, minimize-size
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from pathlib import Path
from PIL import Image

dest = Path(sys.argv[1])
img = Image.new('RGB', (64, 48), (10, 200, 30))
img.save(dest, 'WEBP', quality=80, method=6, minimize_size=True)
assert dest.stat().st_size > 0

with Image.open(dest) as out:
    out.load()
    assert out.mode == 'RGB', out.mode
    assert out.size == (64, 48), out.size
    assert out.format == 'WEBP', out.format
PY
