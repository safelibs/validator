#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-tar-to-zip
# @title: python-libarchive-c tar to zip copy
# @description: Reads tar entries and writes them into a ZIP archive through python-libarchive-c.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-tar-to-zip"
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

tar_path = tmpdir / "input.tar"
zip_path = tmpdir / "output.zip"
expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n"}
write(tar_path, expected)
with libarchive.file_reader(str(tar_path)) as entries, libarchive.file_writer(str(zip_path), "zip") as writer:
    writer.add_entries(entries)
assert read(zip_path) == expected
print("tar-to-zip")
PY
