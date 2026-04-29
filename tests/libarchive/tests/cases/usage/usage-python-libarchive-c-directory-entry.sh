#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-directory-entry
# @title: python-libarchive-c directory entry
# @description: Uses python-libarchive-c to handle directory entries through libarchive.
# @timeout: 180
# @tags: usage, archive
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="directory-entry"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$workload" "$tmpdir"
from pathlib import Path
import sys
import libarchive

workload = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write_archive(path, *, gzip=False):
    with libarchive.file_writer(str(path), "gnutar", "gzip" if gzip else None) as writer:
        writer.add_file_from_memory("alpha.txt", len(b"alpha\n"), b"alpha\n")
        writer.add_file_from_memory("beta.txt", len(b"beta\n"), b"beta\n")

def read_entries(path):
    entries = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            data = b"".join(entry.get_blocks())
            entries.append((entry.pathname, entry.size, data))
    return entries

archive_path = tmpdir / "input.tar"

directory_archive = tmpdir / "directory.tar"
with libarchive.file_writer(str(directory_archive), "gnutar") as writer:
    writer.add_file_from_memory("tree/", 0, b"", filetype=0o040000, permission=0o755)
    writer.add_file_from_memory("tree/nested.txt", len(b"nested\n"), b"nested\n")
names = [name for name, _, _ in read_entries(directory_archive)]
print("directory", ",".join(names))
assert "tree/" in names and "tree/nested.txt" in names
PY
