#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-empty-tar-no-entries
# @title: python-libarchive-c empty tar (zero members) round trip
# @description: Opens a libarchive.file_writer for gnutar and closes it without adding any entries, producing the canonical zero-member tar (two 512-byte all-zero EOF records). Asserts the on-disk file is exactly 1024 bytes and contains only NUL bytes, then opens it through libarchive.file_reader and confirms the entry iterator yields zero entries with no exception. Exercises the zero-entry corner case distinct from existing tests that include an empty-payload member.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-empty-tar-no-entries"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "empty.tar"
with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    pass  # no add_file_from_memory calls

raw = archive_path.read_bytes()
# Two 512-byte zero blocks per POSIX.
assert len(raw) == 1024, len(raw)
assert set(raw) == {0}, sorted(set(raw))[:8]

names = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        names.append(entry.pathname)
        b"".join(entry.get_blocks())

assert names == [], names

# Repeat through memory_reader for parity.
mem_names = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        mem_names.append(entry.pathname)
        b"".join(entry.get_blocks())
assert mem_names == [], mem_names
print("empty-tar", len(raw))
PY
