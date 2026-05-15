#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-load-from-bytesio-preserves-size
# @title: Pillow can decode a TIFF directly from an in-memory BytesIO buffer
# @description: Saves a 6x5 mode-RGB image into a BytesIO via Image.save(buf, format='TIFF'), seeks the buffer to 0, opens it with Image.open(buf), loads, and asserts the resulting size is exactly (6, 5) and mode is 'RGB', confirming libtiff's stream-based decode path handles a non-filesystem reader.
# @timeout: 60
# @tags: usage, tiff, python, bytesio, stream, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import io
from PIL import Image

buf = io.BytesIO()
src = Image.new('RGB', (6, 5), (50, 100, 150))
src.save(buf, format='TIFF')
buf.seek(0)
with Image.open(buf) as r:
    r.load()
    assert r.size == (6, 5), r.size
    assert r.mode == 'RGB', r.mode
    print('ok bytesio size=%s mode=%s' % (r.size, r.mode))
PY
