#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-cpio-zstd-filter
# @title: python-libarchive-c cpio zstd filter
# @description: Writes a zstd-filtered cpio archive through python-libarchive-c and reads the entries back.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-cpio-zstd-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="cpio", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    result = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

path = tmpdir / "data.cpio.zst"
expected = {
    "small.txt": b"cpio zstd small\n",
    "another.txt": b"cpio zstd another\n",
}
write(path, expected, fmt="cpio", filt="zstd")

# zstd frame magic 0x28b52ffd (little-endian)
head = path.read_bytes()[:4]
assert head == b"\x28\xb5\x2f\xfd", f"unexpected zstd header bytes: {head!r}"

assert read(path) == expected
print("cpio-zstd", len(expected))
PY
