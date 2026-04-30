#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-very-long-path
# @title: python-libarchive-c very long path
# @description: Stores an entry whose pathname exceeds 200 characters in a pax archive and verifies the path roundtrips through python-libarchive-c.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-very-long-path"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# Build a path > 200 characters made of nested directories.
segment = "longsegment" * 4  # 44 chars
parts = [segment + str(i) for i in range(6)]
long_path = "/".join(parts) + "/payload.txt"
assert len(long_path) > 200, len(long_path)

archive_path = tmpdir / "long.tar"
payload = b"deep payload\n"
with libarchive.file_writer(str(archive_path), "pax") as writer:
    writer.add_file_from_memory(long_path, len(payload), payload)

found = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        found[entry.pathname] = b"".join(entry.get_blocks())

assert long_path in found, list(found.keys())
assert found[long_path] == payload, found[long_path]
print("long-path", len(long_path))
PY
