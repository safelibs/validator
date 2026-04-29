#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-zip-to-tar
# @title: python-libarchive-c zip to tar copy
# @description: Reads ZIP entries and writes them into a tar archive through python-libarchive-c.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-zip-to-tar"
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

zip_path = tmpdir / "input.zip"
tar_path = tmpdir / "output.tar"
expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n"}
write(zip_path, expected, fmt="zip")
with libarchive.file_reader(str(zip_path)) as entries, libarchive.file_writer(str(tar_path), "gnutar") as writer:
    writer.add_entries(entries)
assert read(tar_path) == expected
print("zip-to-tar")
PY
