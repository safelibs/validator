#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-ar-svr4-roundtrip
# @title: python-libarchive-c ar svr4 roundtrip
# @description: Writes an ar svr4 (System V) archive through python-libarchive-c and reads back the member payloads.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-ar-svr4-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="ar_svr4", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    out = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out[entry.pathname.rstrip("/")] = b"".join(entry.get_blocks())
    return out

path = tmpdir / "out.a"
expected = {"a.o": b"\x7fELF-stub-a", "b.o": b"\x7fELF-stub-b"}
write(path, expected)
assert path.read_bytes().startswith(b"!<arch>\n"), path.read_bytes()[:8]
got = read(path)
assert got == expected, got
print("ar-svr4", len(got))
PY
