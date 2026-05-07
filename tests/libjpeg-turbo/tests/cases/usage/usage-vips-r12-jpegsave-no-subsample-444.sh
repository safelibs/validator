#!/usr/bin/env bash
# @testcase: usage-vips-r12-jpegsave-no-subsample-444
# @title: vips jpegsave --no-subsample emits a 4:4:4 SOF0 component table
# @description: Saves a JPEG via vips jpegsave with --no-subsample (chroma subsampling disabled) and parses the SOF0 marker to confirm all three components advertise a 1:1 horizontal/vertical sampling factor (0x11), corresponding to 4:4:4.
# @timeout: 60
# @tags: usage, jpeg, image, subsampling
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 48, 36
data = bytes([(((x * 5) ^ (y * 11)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/444.jpg" --no-subsample --Q 85

python3 - "$tmpdir/444.jpg" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
i = data.find(b"\xff\xc0")
assert i > 0, "no SOF0 marker"
# SOF0: FFC0 LL P YY YY XX XX Nf [Ci Hi/Vi Tqi]*Nf
nf = data[i + 9]
assert nf == 3, f"expected 3 components, got {nf}"
# Each component's sampling-factor byte (Hi<<4 | Vi) must be 0x11.
factors = [data[i + 10 + 3 * k + 1] for k in range(3)]
assert factors == [0x11, 0x11, 0x11], f"unexpected sampling factors: {factors}"
PY
