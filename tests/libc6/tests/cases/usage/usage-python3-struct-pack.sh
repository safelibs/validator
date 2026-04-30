#!/usr/bin/env bash
# @testcase: usage-python3-struct-pack
# @title: python3 struct big-endian packing
# @description: Packs a 32-bit integer as big-endian bytes with the python3 struct module and verifies the hex byte order.
# @timeout: 180
# @tags: usage, python, runtime
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-struct-pack"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import struct
packed = struct.pack(">I", 0x12345678)
unpacked = struct.unpack(">I", packed)[0]
with open("'"$tmpdir"'/out", "w") as fh:
    fh.write(packed.hex() + "\n")
    fh.write(str(unpacked) + "\n")
'

validator_assert_contains "$tmpdir/out" '12345678'
validator_assert_contains "$tmpdir/out" '305419896'
