#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-zip-compression-store-option
# @title: python-libarchive-c zip writer with options=zip:compression=store leaves payload uncompressed
# @description: Writes a 100-byte single-character payload through file_writer using options="zip:compression=store" and asserts the resulting zip header reports the entry's compressed size equals the uncompressed size (CRC payload + central directory present), confirming the store mode passes payload bytes through unchanged.
# @timeout: 120
# @tags: usage, archive, zip, compression
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import struct
import sys
from pathlib import Path

import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "store.zip"
payload = b"A" * 100

with libarchive.file_writer(str(arc), "zip", options="zip:compression=store") as writer:
    writer.add_file_from_memory("s.txt", len(payload), payload)

raw = arc.read_bytes()
# Local file header: signature 'PK\x03\x04', then version (2), flags (2),
# method (2 at offset 8), mtime/mdate (4), crc (4), comp_size (4 at offset 18), uncomp_size (4 at offset 22).
assert raw[:4] == b"PK\x03\x04", raw[:4].hex()
method = struct.unpack_from("<H", raw, 8)[0]
comp_size = struct.unpack_from("<I", raw, 18)[0]
uncomp_size = struct.unpack_from("<I", raw, 22)[0]
assert method == 0, ("expected store=0", method)
assert comp_size == uncomp_size == 100, (comp_size, uncomp_size)

seen = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())
assert seen == {"s.txt": payload}, seen
print("zip-store", method, comp_size, uncomp_size)
PY
