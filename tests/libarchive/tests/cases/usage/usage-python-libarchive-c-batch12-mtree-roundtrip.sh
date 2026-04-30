#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-mtree-roundtrip
# @title: python-libarchive-c mtree roundtrip
# @description: Writes an mtree-format archive via python-libarchive-c and verifies entry names roundtrip on read.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-mtree-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="mtree", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def names(path):
    out = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out.append(entry.pathname)
            b"".join(entry.get_blocks())
    return out

path = tmpdir / "out.mtree"
expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n", "gamma.txt": b"gamma\n"}
write(path, expected)
header = path.read_bytes()[:7]
assert header.startswith(b"#mtree"), header
listed = names(path)
# libarchive's mtree reader returns paths with a leading "./" prefix; strip
# it before comparing so the assertion targets the structural roundtrip.
normalised = sorted(name[2:] if name.startswith("./") else name for name in listed)
assert normalised == sorted(expected.keys()), listed
print("mtree", len(listed))
PY
