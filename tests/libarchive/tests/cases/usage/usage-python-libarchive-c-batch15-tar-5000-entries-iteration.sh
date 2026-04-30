#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-tar-5000-entries-iteration
# @title: python-libarchive-c tar 5000 entries iteration
# @description: Writes 5000 small entries into a gnutar archive via add_file_from_memory, then reads the archive back and verifies the iterator yields exactly 5000 entries in insertion order with their declared sizes intact. Stresses the libarchive read iterator across a much larger entry count than the existing 1000-entry case so iteration cost and bookkeeping are exercised.
# @timeout: 480
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-tar-5000-entries-iteration"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "many.tar"
total = 5000
expected_names = [f"entry-{i:05d}.txt" for i in range(total)]

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    for name in expected_names:
        payload = name.encode() + b"\n"
        writer.add_file_from_memory(name, len(payload), payload)

names_seen = []
sizes_seen = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        names_seen.append(entry.pathname)
        sizes_seen[entry.pathname] = entry.size
        b"".join(entry.get_blocks())

assert len(names_seen) == total, len(names_seen)
assert names_seen == expected_names, (names_seen[:3], expected_names[:3])
# Spot-check a handful of sizes spread across the archive.
for idx in (0, 1234, 2500, 4999):
    name = expected_names[idx]
    assert sizes_seen[name] == len(name) + 1, (name, sizes_seen[name])
print("iter-5000", len(names_seen))
PY
