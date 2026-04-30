#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-zip-read-format
# @title: python-libarchive-c zip explicit format read
# @description: Reads a zip archive with explicit format_name="zip" through python-libarchive-c file_reader.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-zip-read-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write_zip(path, entries):
    with libarchive.file_writer(str(path), "zip") as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read_zip(path):
    out = {}
    with libarchive.file_reader(str(path), format_name="zip") as archive:
        for entry in archive:
            out[entry.pathname] = b"".join(entry.get_blocks())
    return out

path = tmpdir / "out.zip"
expected = {"x.txt": b"x payload\n", "y.txt": b"y payload\n"}
write_zip(path, expected)
assert path.read_bytes()[:2] == b"PK", path.read_bytes()[:2]
got = read_zip(path)
assert got == expected, got
print("zip-format-read", len(got))
PY
