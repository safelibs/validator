#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-tar-extract
# @title: python-libarchive-c tar extract
# @description: Uses python-libarchive-c to extract files from a tar archive through libarchive.
# @timeout: 180
# @tags: usage, archive
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="tar-extract"
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
out = tmpdir / "out"
out.mkdir()
for name, _, data in read_entries(archive_path):
    (out / name).write_bytes(data)
print((out / "alpha.txt").read_text().strip())
assert (out / "beta.txt").read_text() == "beta\n"
PY
