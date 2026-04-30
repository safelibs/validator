#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-targz-bytesio-memory-reader
# @title: python-libarchive-c tar.gz from BytesIO via memory_reader
# @description: Writes a gzip-filtered tar to disk, loads its bytes through io.BytesIO and feeds the buffer's value into libarchive.memory_reader, asserting both entries roundtrip with payload.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-targz-bytesio-memory-reader"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import io
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="gnutar", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def memory_read_bytes(payload):
    out = {}
    with libarchive.memory_reader(payload) as archive:
        for entry in archive:
            out[entry.pathname] = b"".join(entry.get_blocks())
    return out

path = tmpdir / "buf.tar.gz"
expected = {"first.txt": b"first payload\n", "second.txt": b"second payload\n"}
write(path, expected, filt="gzip")

# Round-trip the on-disk archive through a BytesIO buffer; memory_reader
# accepts any bytes-like buffer-supporting object's value.
buffer = io.BytesIO()
buffer.write(path.read_bytes())
assert buffer.tell() == path.stat().st_size, (buffer.tell(), path.stat().st_size)
buffer.seek(0)
got = memory_read_bytes(buffer.getvalue())
assert got == expected, got
# Also confirm BytesIO.read() yields the same payload.
buffer.seek(0)
assert memory_read_bytes(buffer.read()) == expected
print("targz-bytesio", len(got))
PY
