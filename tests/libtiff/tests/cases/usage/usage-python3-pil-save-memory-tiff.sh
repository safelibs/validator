#!/usr/bin/env bash
# @testcase: usage-python3-pil-save-memory-tiff
# @title: Pillow saves TIFF to memory
# @description: Saves a TIFF into an in-memory buffer with Pillow, reloads it, and verifies the buffered image stays decodable.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-save-memory-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from io import BytesIO
from pathlib import Path
from PIL import Image
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

with Image.open(fixture) as im:
    handle = BytesIO()
    im.save(handle, "TIFF")
payload = handle.getvalue()
assert len(payload) > 0
with Image.open(BytesIO(payload)) as im:
    assert im.size[0] > 0 and im.size[1] > 0
    print("memory-save", im.size)
PY
