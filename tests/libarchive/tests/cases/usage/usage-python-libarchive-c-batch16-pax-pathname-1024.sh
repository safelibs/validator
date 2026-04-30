#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-pax-pathname-1024
# @title: python-libarchive-c pax pathname above 1024 chars
# @description: Stores an entry whose pathname is well above 1024 characters in a pax archive; ustar header path/prefix fields cap at 100/155 bytes so libarchive must emit a pax extended header carrying the long path. Reads it back and verifies the full pathname survives the round trip and the payload is intact.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-pax-pathname-1024"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# Build a path well above 1024 characters using nested directory segments so
# no individual segment exceeds typical filesystem NAME_MAX limits.
segment = "p" * 60  # 60 chars per segment
parts = [segment + str(i).zfill(3) for i in range(20)]  # 20 segments * ~63 = 1260+
long_path = "/".join(parts) + "/payload.txt"
assert len(long_path) > 1024, len(long_path)

archive_path = tmpdir / "huge.pax"
payload = b"payload behind a very long pax pathname\n" * 8

with libarchive.file_writer(str(archive_path), "pax") as writer:
    writer.add_file_from_memory(long_path, len(payload), payload)

found = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        found[entry.pathname] = b"".join(entry.get_blocks())

assert long_path in found, list(found.keys())[:1]
assert found[long_path] == payload, len(found[long_path])
print("pax-pathname-1024+", len(long_path))
PY
