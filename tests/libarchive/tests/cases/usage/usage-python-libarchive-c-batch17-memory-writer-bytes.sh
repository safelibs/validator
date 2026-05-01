#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-memory-writer-bytes
# @title: python-libarchive-c custom_writer captures bytes in memory
# @description: Builds a gnutar archive entirely in memory by using libarchive.custom_writer with a Python callback that appends each output chunk to a bytearray, then re-parses the resulting bytes through libarchive.memory_reader. Confirms that the in-memory writer code path (no on-disk file) produces a stream that round trips through the memory_reader and recovers every entry pathname plus its payload exactly.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-memory-writer-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

expected = {
    "alpha.txt": b"alpha in memory\n" * 8,
    "nested/beta.txt": b"beta in memory bytes\n" * 16,
    "gamma.bin": bytes(range(128)),
}

captured = bytearray()

def write_cb(data):
    # data is a ctypes char array; copy bytes out before libarchive reuses the buffer.
    captured.extend(bytes(data))
    return len(data)

with libarchive.custom_writer(write_cb, "gnutar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = bytes(captured)
assert len(raw) > 0, len(raw)
# tar streams must be a non-empty multiple of 512 bytes per the ustar spec.
assert len(raw) % 512 == 0, len(raw)

got = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("memory-writer-bytes", len(raw), len(got))
PY
