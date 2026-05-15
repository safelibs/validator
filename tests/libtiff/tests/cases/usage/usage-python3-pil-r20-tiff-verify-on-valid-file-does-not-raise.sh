#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-verify-on-valid-file-does-not-raise
# @title: Pillow Image.verify on a freshly-saved TIFF completes without raising
# @description: Saves a 5x5 RGB TIFF via Pillow, opens it again with Image.open, calls .verify() within a try/except block, and asserts no exception was raised, confirming Pillow's libtiff-backed verifier accepts a well-formed TIFF container as valid.
# @timeout: 60
# @tags: usage, tiff, python, verify, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/verify.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

Image.new('RGB', (5, 5), (1, 2, 3)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    try:
        r.verify()
    except Exception as exc:
        raise SystemExit('verify raised: %r' % exc)
print('ok verify')
PY
