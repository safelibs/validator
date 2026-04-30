#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-pax-gzip-filter
# @title: python-libarchive-c pax gzip filter
# @description: Writes a gzip-filtered pax archive through python-libarchive-c and validates the readback payload.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-pax-gzip-filter"
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

path = tmpdir / "data.pax.gz"
expected = {
    "doc/notes.txt": b"pax gzip notes\n",
    "doc/readme.txt": b"pax gzip readme\n",
}
write(path, expected, fmt="pax", filt="gzip")

head = path.read_bytes()[:2]
assert head == b"\x1f\x8b", f"unexpected gzip header bytes: {head!r}"

assert read(path) == expected
print("pax-gzip", len(expected))
PY
