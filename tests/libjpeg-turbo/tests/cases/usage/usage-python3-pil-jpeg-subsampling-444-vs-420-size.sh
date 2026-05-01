#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-subsampling-444-vs-420-size
# @title: Pillow JPEG 4:4:4 vs 4:2:0 size
# @description: Saves the same image at the same quality with subsampling=0 (4:4:4) and subsampling=2 (4:2:0) via Pillow and asserts the 4:4:4 output is larger, confirming libjpeg-turbo honors the chroma subsampling selector.
# @timeout: 180
# @tags: usage, jpeg, python, encoder
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
W, H = 192, 192
src = Image.new('RGB', (W, H))
# Strong chroma content so subsampling actually changes the bitstream.
src.putdata([(((x * 11) & 255), ((y * 13) & 255), (((x + y) * 7) & 255))
             for y in range(H) for x in range(W)])

p444 = tmpdir / 's444.jpg'
p420 = tmpdir / 's420.jpg'
src.save(p444, 'JPEG', quality=85, subsampling=0)
src.save(p420, 'JPEG', quality=85, subsampling=2)

s444 = p444.stat().st_size
s420 = p420.stat().st_size
print('444', s444, '420', s420)
assert s444 > s420, f'4:4:4 should be larger than 4:2:0, got 444={s444} 420={s420}'

# SOF0 component descriptors carry the H/V sampling factors. Walk the JPEG
# marker segments from the start of stream so we do not collide with
# 0xFFC0 byte pairs that occur inside quantization or huffman tables.
def sof0_sampling(data: bytes) -> tuple:
    assert data[:2] == b'\xff\xd8', 'not a JPEG'
    i = 2
    while i < len(data) - 1:
        if data[i] != 0xFF:
            raise AssertionError(f'expected marker at {i}, got {data[i]:#x}')
        # Skip fill bytes (0xFF padding).
        while i < len(data) and data[i] == 0xFF:
            i += 1
        marker = data[i]
        i += 1
        if marker == 0xC0:  # SOF0
            # length(2) + precision(1) + height(2) + width(2) + nf(1) + components...
            nf = data[i + 7]
            out = []
            for c in range(nf):
                hv = data[i + 8 + c * 3 + 1]
                out.append((hv >> 4, hv & 0x0F))
            return tuple(out)
        if marker in (0xD8, 0x01) or 0xD0 <= marker <= 0xD7:
            # SOI / TEM / RSTn carry no length.
            continue
        if marker == 0xD9:  # EOI
            break
        # All other markers carry a 2-byte big-endian length that includes itself.
        seg_len = (data[i] << 8) | data[i + 1]
        i += seg_len
        if marker == 0xDA:  # SOS — entropy data follows; SOF must precede SOS.
            break
    raise AssertionError('SOF0 marker not found')

s444_sampling = sof0_sampling(p444.read_bytes())
s420_sampling = sof0_sampling(p420.read_bytes())
print('444 sampling', s444_sampling, '420 sampling', s420_sampling)
# 4:4:4 -> all components H=1,V=1; 4:2:0 -> Y is H=2,V=2 with 1,1 chroma.
assert s444_sampling == ((1, 1), (1, 1), (1, 1)), s444_sampling
assert s420_sampling[0] == (2, 2), s420_sampling
PYCASE
