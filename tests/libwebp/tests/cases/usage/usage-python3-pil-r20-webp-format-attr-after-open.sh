#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-webp-format-attr-after-open
# @title: Pillow Image.open on a saved WEBP exposes img.format == 'WEBP'
# @description: Saves an RGB image to WEBP via Pillow, reopens with Image.open, calls load(), and asserts img.format is exactly the string 'WEBP' — pinning the libwebp-backed format identifier reported by PIL.
# @timeout: 60
# @tags: usage, python3-pil, webp, format-attr, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGB', (32, 24), (50, 150, 250))
img.save(sys.argv[1], 'WEBP', quality=80)

with Image.open(sys.argv[1]) as out:
    out.load()
    assert out.format == 'WEBP', out.format
PY
