#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-method-six-save-batch11
# @title: Pillow WebP method six save
# @description: Saves a WebP with encoder method 6 and verifies it reopens.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-method-six-save-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from io import BytesIO
from PIL import Image, ImageSequence, ImageOps, features
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
base = Image.new('RGB', (5, 4), (20, 80, 160))

def reopen(path):
    im = Image.open(path)
    im.load()
    return im

out = tmpdir / 'method.webp'
base.save(out, 'WEBP', quality=80, method=6)
im = reopen(out)
assert im.format == 'WEBP'
print(out.stat().st_size)
PYCASE
