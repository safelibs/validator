#!/usr/bin/env bash
# @testcase: usage-python3-pil-bytesio-open-tiff
# @title: Pillow opens TIFF from memory
# @description: Loads a TIFF from an in-memory byte buffer with Pillow and verifies the decoded image dimensions.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-bytesio-open-tiff"
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

payload = Path(fixture).read_bytes()
with Image.open(BytesIO(payload)) as im:
    im.load()
    assert im.size[0] > 0 and im.size[1] > 0
    print("bytesio", im.size)
PY
