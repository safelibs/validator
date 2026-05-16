#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-jpeg-paste-with-mask-quarter
# @title: Pillow Image.paste with an L-mode mask blends a JPEG-decoded overlay onto a base
# @description: Decodes a previously-saved JPEG overlay via PIL, pastes it onto a solid RGB base with an L-mode 128-value mask covering a centered quarter, encodes the result as JPEG, and asserts the final image size remains 64x64 and that the centered region's pixel red channel is strictly between the base red value 10 and the overlay red value 200 - locking in libjpeg-turbo's encode/decode path through PIL's Image.paste with a non-trivial alpha mask.
# @timeout: 180
# @tags: usage, jpeg, python, paste, mask, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base_dir = Path(sys.argv[1])

overlay = Image.new("RGB", (32, 32), (200, 30, 30))
overlay_path = base_dir / "overlay.jpg"
overlay.save(overlay_path, "JPEG", quality=95)

# Decode the overlay back from JPEG, so libjpeg-turbo participates on the path.
decoded_overlay = Image.open(overlay_path).convert("RGB")
assert decoded_overlay.size == (32, 32)

base = Image.new("RGB", (64, 64), (10, 10, 10))
mask = Image.new("L", (32, 32), 128)
base.paste(decoded_overlay, (16, 16), mask=mask)

out = base_dir / "pasted.jpg"
base.save(out, "JPEG", quality=95)

result = Image.open(out).convert("RGB")
assert result.size == (64, 64), result.size

# A pixel at the centre of the mask region should be a blend between base red 10 and overlay red ~200.
r, g, b = result.getpixel((32, 32))
assert 30 < r < 200, ("unexpected blended red", r)
PY
