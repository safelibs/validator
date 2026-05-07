#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-jpeg-icc-profile-app2-marker
# @title: Pillow JPEG icc_profile= writes an APP2 ICC_PROFILE segment
# @description: Saves a JPEG via Pillow with a synthetic icc_profile bytes payload and asserts the encoded byte stream contains the APP2 marker followed by the "ICC_PROFILE" identifier, exercising the libjpeg-turbo APP2 ICC writer.
# @timeout: 60
# @tags: usage, jpeg, python, color
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
out = base / "icc.jpg"
src = Image.new("RGB", (16, 12))
src.putdata([((x * 13) % 256, (y * 7) % 256, ((x + y) * 11) % 256)
             for y in range(12) for x in range(16)])

icc = bytes((i * 5 + 11) % 256 for i in range(256))
src.save(out, "JPEG", quality=85, icc_profile=icc)

data = out.read_bytes()
# APP2 marker is FFE2; ICC profile chunks carry the literal "ICC_PROFILE\0" id.
i = data.find(b"ICC_PROFILE\x00")
assert i > 0, "missing ICC_PROFILE identifier in JPEG"
# The APP2 marker must precede the identifier within ~16 bytes.
assert b"\xff\xe2" in data[max(0, i - 16):i], "no APP2 marker before ICC_PROFILE"

with Image.open(out) as im:
    im.load()
    assert im.info.get("icc_profile") == icc, "icc_profile bytes did not round-trip"
PY
