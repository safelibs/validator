#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-zip-roundtrip
# @title: python-libarchive-c zip roundtrip
# @description: Uses python-libarchive-c to write and read ZIP archive entries through libarchive.
# @timeout: 180
# @tags: usage, archive
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="zip-roundtrip"
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

zip_archive = tmpdir / "roundtrip.zip"
expected = {
    "zip-alpha.txt": b"zip alpha\n",
    "zip-beta.txt": b"zip beta\n",
}
with libarchive.file_writer(str(zip_archive), "zip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)
data = {name: body for name, _, body in read_entries(zip_archive)}
print("zip-roundtrip", ",".join(sorted(data)))
assert data == expected
PY
