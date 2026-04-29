#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-copy-mode
# @title: python-libarchive-c copy mode
# @description: Uses python-libarchive-c to copy archived files through libarchive.
# @timeout: 180
# @tags: usage, archive
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="copy-mode"
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

write_archive(archive_path)
copy_path = tmpdir / "copy.tar"
with libarchive.file_reader(str(archive_path)) as entries, libarchive.file_writer(str(copy_path), "gnutar") as writer:
    writer.add_entries(entries)
copied = {name: body.decode() for name, _, body in read_entries(copy_path)}
print(copied)
assert copied["alpha.txt"] == "alpha\n"
PY
