#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-7zip-read
# @title: python-libarchive-c 7zip read
# @description: Writes a 7z archive via python-libarchive-c then reads its entries back through libarchive.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-7zip-read"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="7zip", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    out = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out[entry.pathname] = b"".join(entry.get_blocks())
    return out

path = tmpdir / "out.7z"
expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta payload\n"}
write(path, expected)
assert path.read_bytes()[:6] == b"7z\xbc\xaf\x27\x1c", path.read_bytes()[:6]
got = read(path)
assert got == expected, got
print("7zip", len(got))
PY
