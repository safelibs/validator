#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-pax-zstd-filter
# @title: python-libarchive-c pax zstd filter
# @description: Writes a zstd-filtered pax archive through python-libarchive-c and verifies the readback payload.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-pax-zstd-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="pax", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    result = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

path = tmpdir / "data.pax.zst"
expected = {
    "logs/info.txt": b"pax zstd info\n",
    "logs/warn.txt": b"pax zstd warn\n",
}
write(path, expected, fmt="pax", filt="zstd")

head = path.read_bytes()[:4]
assert head == b"\x28\xb5\x2f\xfd", f"unexpected zstd header bytes: {head!r}"

assert read(path) == expected
print("pax-zstd", len(expected))
PY
