#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-feature-check-batch11
# @title: Pillow WebP feature check
# @description: Checks Pillow reports WebP feature support.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-feature-check-batch11"
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

assert features.check('webp')
print('webp')
PYCASE
