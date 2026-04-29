#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-lzip-filter
# @title: python-libarchive-c lzip filter
# @description: Creates an lzip-filtered tar archive and reads it back through python-libarchive-c.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-lzip-filter"
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

def metadata(path):
    rows = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            rows.append((entry.pathname, entry.size))
            b"".join(entry.get_blocks())
    return rows

path = tmpdir / "data.tar.lz"
expected = {"lzip.txt": b"lzip payload\n"}
write(path, expected, filt="lzip")
assert read(path) == expected
print("lzip")
PY
