#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-verify-jpeg
# @title: Pillow Image.verify on JPEG
# @description: Runs Image.verify() against a freshly-encoded JPEG and confirms it returns without raising and reports the file format as JPEG.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

out = sys.argv[1] + "/test.jpg"
im = Image.new("RGB", (8, 8), (10, 50, 200))
im.save(out, "JPEG")

with Image.open(out) as probe:
    assert probe.format == "JPEG", probe.format
    probe.verify()  # raises on corruption
print("verify-ok")
PY
