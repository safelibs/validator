#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-nested-paths
# @title: python-libarchive-c nested paths
# @description: Uses python-libarchive-c to preserve nested and spaced entry paths through libarchive.
# @timeout: 180
# @tags: usage, archive
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="nested-paths"
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

nested_archive = tmpdir / "nested.tar"
expected = {
    "dir/sub.txt": b"sub\n",
    "dir/space name.txt": b"space name\n",
}
with libarchive.file_writer(str(nested_archive), "gnutar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)
data = {name: body for name, _, body in read_entries(nested_archive)}
print("nested-paths", ",".join(sorted(data)))
assert data == expected
PY
