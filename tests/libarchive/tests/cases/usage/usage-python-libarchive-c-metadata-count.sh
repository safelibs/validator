#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-metadata-count
# @title: python-libarchive-c metadata count
# @description: Reads archive metadata through python-libarchive-c and verifies the expected entry count and byte sizes.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-metadata-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="gnutar", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    result = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

def read_bytes(payload):
    result = {}
    with libarchive.memory_reader(payload) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

def metadata(path):
    rows = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            rows.append((entry.pathname, entry.size))
            b"".join(entry.get_blocks())
    return rows

path = tmpdir / "metadata.tar"
expected = {
    "zero.txt": b"",
    "small.txt": b"abc\n",
    "big.txt": b"0123456789abcdef",
}
write(path, expected)
rows = metadata(path)
assert len(rows) == 3
assert ("zero.txt", 0) in rows
assert ("big.txt", 16) in rows
print("metadata", len(rows))
PY
