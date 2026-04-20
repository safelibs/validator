#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/alpha.webp"
from PIL import Image
import sys

image = Image.new("RGBA", (2, 2))
image.putdata([
    (255, 0, 0, 0),
    (0, 255, 0, 64),
    (0, 0, 255, 128),
    (255, 255, 0, 255),
])
image.save(sys.argv[1], "WEBP", lossless=True)

with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    assert reopened.size == (2, 2), reopened.size
    assert "A" in reopened.getbands(), reopened.getbands()
    assert list(reopened.getchannel("A").getdata()) == [0, 64, 128, 255]
    print("webp-alpha", reopened.size, reopened.mode)
PY
