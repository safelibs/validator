#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-ustar-explicit-directory
# @title: python-libarchive-c ustar explicit directory entry
# @description: Writes a ustar archive containing an explicit directory entry (filetype=0o040000) plus a child file via python-libarchive-c and asserts the listed members include both the directory and the child while the directory entry exposes size 0.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-ustar-explicit-directory"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "dirs.tar"
with libarchive.file_writer(str(path), "ustar") as writer:
    writer.add_file_from_memory(
        "subtree/", 0, b"", filetype=0o040000, permission=0o755
    )
    writer.add_file_from_memory(
        "subtree/leaf.txt", len(b"leaf\n"), b"leaf\n"
    )

records = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        records.append((entry.pathname, entry.isdir, entry.size))
        b"".join(entry.get_blocks())

names = [name for name, _, _ in records]
assert "subtree/" in names, names
assert "subtree/leaf.txt" in names, names
dir_row = next(row for row in records if row[0] == "subtree/")
assert dir_row[1] is True, dir_row
assert dir_row[2] == 0, dir_row
file_row = next(row for row in records if row[0] == "subtree/leaf.txt")
assert file_row[1] is False, file_row
assert file_row[2] == len(b"leaf\n"), file_row
print("ustar-dir", records)
PY
