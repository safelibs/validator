#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-iterate-skip-data
# @title: python-libarchive-c iterate without consuming entry data
# @description: Writes a multi-entry gnutar archive, then reads it back and walks every entry without ever calling entry.get_blocks(). Verifies that pathnames and sizes are still exposed correctly and that iteration completes cleanly when the consumer skips over each entry's data. Exercises libarchive's auto-skip path between headers, which is the default behaviour when the caller never reads from a header.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-iterate-skip-data"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "skip.tar"
plan = [
    ("small.txt", b"small payload\n"),
    ("medium.txt", b"medium payload bytes " * 32),
    ("large.txt", b"large payload chunk\n" * 4096),
    ("final.txt", b"final payload\n"),
]

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    for name, payload in plan:
        writer.add_file_from_memory(name, len(payload), payload)

names_seen = []
sizes_seen = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        # Deliberately skip the data; libarchive must auto-advance past the
        # current entry payload before the next header is parseable.
        names_seen.append(entry.pathname)
        sizes_seen.append(entry.size)

expected_names = [name for name, _ in plan]
expected_sizes = [len(payload) for _, payload in plan]
assert names_seen == expected_names, (names_seen, expected_names)
assert sizes_seen == expected_sizes, (sizes_seen, expected_sizes)
print("skip-data", names_seen)
PY
