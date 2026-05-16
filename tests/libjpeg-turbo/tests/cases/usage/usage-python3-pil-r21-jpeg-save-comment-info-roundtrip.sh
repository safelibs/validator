#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-jpeg-save-comment-info-roundtrip
# @title: Pillow JPEG save comment kwarg appears in info["comment"] after re-open
# @description: Encodes a small RGB image with Pillow's JPEG save comment=b"r21-comment-marker" kwarg, re-opens the result and asserts im.info["comment"] equals that exact byte string AND that the saved file contains a COM (FFFE) marker byte sequence in its first 8 KiB - locking in libjpeg-turbo's COM marker emission via Pillow's comment kwarg and the corresponding info["comment"] decode path.
# @timeout: 120
# @tags: usage, jpeg, python, comment, com-marker, r21
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
out = base / "c.jpg"
expected = b"r21-comment-marker"
im = Image.new("RGB", (24, 16), (100, 50, 25))
im.save(out, "JPEG", comment=expected, quality=85)

# Assert the COM (FFFE) marker appears somewhere in the file header.
data = out.read_bytes()
assert b"\xff\xfe" in data[:8192], "missing JPEG COM marker"

with Image.open(out) as probe:
    got = probe.info.get("comment")
    assert got == expected, ("expected", expected, "got", got)
PY
