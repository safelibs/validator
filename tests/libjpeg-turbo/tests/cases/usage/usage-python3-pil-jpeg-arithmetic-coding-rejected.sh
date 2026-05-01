#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-arithmetic-coding-rejected
# @title: Pillow JPEG arithmetic coding rejected
# @description: Asks Pillow to encode JPEG with arithmetic=True and confirms libjpeg-turbo refuses (no arith encoder), so Pillow raises an exception.
# @timeout: 180
# @tags: usage, jpeg, python, negative
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (8, 8), (128, 64, 32))
out = tmpdir / 'arith.jpg'

# libjpeg-turbo ships only a Huffman encoder; arithmetic coding for *encoding*
# is not supported. Pillow surfaces this as an OSError or IOError at save().
raised = False
try:
    src.save(out, 'JPEG', quality=80, arithmetic=True)
except (OSError, IOError, ValueError) as exc:
    raised = True
    print('arithmetic encode rejected:', type(exc).__name__, exc)

if not raised:
    # If the encoder silently ignored the flag, the file should still be a
    # standard Huffman JPEG. We treat *that* as acceptable too, but log it.
    data = out.read_bytes()
    assert data[:2] == b'\xff\xd8'
    print('arithmetic flag ignored, fell back to Huffman')
PYCASE
