#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-tar-1000-entries
# @title: python-libarchive-c tar 1000 entries
# @description: Writes 1000 small entries into a tar archive via python-libarchive-c and verifies count and ordering on read.
# @timeout: 240
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-tar-1000-entries"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "many.tar"
expected = [f"file-{i:04d}.txt" for i in range(1000)]
with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    for name in expected:
        payload = name.encode() + b"\n"
        writer.add_file_from_memory(name, len(payload), payload)

listed = []
sizes = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        listed.append(entry.pathname)
        sizes[entry.pathname] = entry.size
        b"".join(entry.get_blocks())

assert listed == expected, (listed[:5], expected[:5], len(listed))
assert sizes["file-0500.txt"] == len("file-0500.txt") + 1
print("count", len(listed))
PY
