#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-zip-deflate-large-roundtrip
# @title: python-libarchive-c zip+deflate roundtrips a >1MB payload
# @description: Writes a single-entry zip archive with the deflate filter and a 1.5 MiB payload, then reads it back via file_reader and confirms the on-disk PK\x03\x04 magic, that entry.size matches the source byte length, and that the streamed payload is byte-equal under sha256.
# @timeout: 240
# @tags: usage, archive, zip, deflate, large
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import hashlib
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "big.zip"
size = 1_500_000
payload = bytes(((i * 37 + 11) & 0xff) for i in range(size))
src_sha = hashlib.sha256(payload).hexdigest()

with libarchive.file_writer(str(arc), "zip", "deflate") as writer:
    writer.add_file_from_memory("big.bin", len(payload), payload)

magic = arc.read_bytes()[:4]
assert magic == b"PK\x03\x04", magic.hex()

count = 0
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        count += 1
        h = hashlib.sha256()
        for block in entry.get_blocks():
            h.update(block)
        assert entry.pathname == "big.bin", entry.pathname
        assert entry.size == size, entry.size
        assert h.hexdigest() == src_sha, (h.hexdigest(), src_sha)

assert count == 1, count
print("zip-deflate-large", size, src_sha[:16])
PY
