#!/usr/bin/env bash
# @testcase: usage-netpbm-r13-pngtopam-rgba-from-rgba-png
# @title: netpbm pngtopam -alphapam decodes an RGBA PNG into a 4-channel RGB_ALPHA PAM
# @description: Encodes an RGBA PAM into a PNG via pamtopng, decodes it back with pngtopam -alphapam, and verifies the result is a P7-magic PAM with DEPTH 4, MAXVAL 255, and TUPLTYPE RGB_ALPHA, locking in pngtopam's alpha-preserving decode path distinct from the existing -alpha extract-mask test which yields a single-channel PGM.
# @timeout: 180
# @tags: usage, png, netpbm, alpha-pam
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
W, H = 12, 8
header = f'P7\nWIDTH {W}\nHEIGHT {H}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n'
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes((x * 20 & 0xff, y * 30 & 0xff, 64, 128 + (x * 10 % 128)))
open(sys.argv[1], 'wb').write(header.encode() + body)
PY

pamtopng "$tmpdir/in.pam" >"$tmpdir/in.png"

pngtopam -alphapam "$tmpdir/in.png" >"$tmpdir/out.pam"

# Parse the PAM header.
python3 - "$tmpdir/out.pam" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
header, _, _ = data.partition(b'ENDHDR\n')
fields = {}
for line in header.splitlines():
    if not line or line.startswith(b'#'):
        continue
    if line == b'P7':
        fields['MAGIC'] = 'P7'
        continue
    k, _, v = line.partition(b' ')
    fields[k.decode()] = v.decode().strip()
assert fields.get('MAGIC') == 'P7', fields
assert fields.get('WIDTH') == '12', fields
assert fields.get('HEIGHT') == '8', fields
assert fields.get('DEPTH') == '4', fields
assert fields.get('MAXVAL') == '255', fields
assert fields.get('TUPLTYPE') == 'RGB_ALPHA', fields
PY
