#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-archive-entry-free-via-ctypes
# @title: python-libarchive-c manual archive_entry_new + archive_entry_free via ctypes
# @description: Allocates an archive_entry by calling archive_entry_new directly through libarchive.so.13 (bypassing libarchive_c's new_archive_entry context manager), populates it, writes one entry, then explicitly cleans it up by calling archive_entry_free via ctypes. Verifies the resulting tar parses correctly afterwards. Exercises the manual lifecycle path that a C consumer would use.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-archive-entry-free-via-ctypes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import ctypes
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry
from libarchive.ffi import (
    REGULAR_FILE,
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

so = ctypes.CDLL("libarchive.so.13")
entry_new = so.archive_entry_new
entry_new.argtypes = []
entry_new.restype = ctypes.c_void_p
entry_free = so.archive_entry_free
entry_free.argtypes = [ctypes.c_void_p]
entry_free.restype = None

path = tmpdir / "manual.tar"
payload_a = b"manually allocated entry payload\n"
payload_b = b"second manually allocated entry\n"

with libarchive.file_writer(str(path), "ustar") as writer:
    archive_p = writer._pointer

    # Manually allocated entry #1: do NOT use the contextmanager; instead call
    # archive_entry_free explicitly when done.
    ent1 = entry_new()
    assert ent1, "archive_entry_new returned NULL"
    try:
        ArchiveEntry(None, ent1).pathname = "manual-1.txt"
        entry_set_filetype(ent1, REGULAR_FILE)
        entry_set_perm(ent1, 0o644)
        entry_set_size(ent1, len(payload_a))
        write_header(archive_p, ent1)
        write_data(archive_p, payload_a, len(payload_a))
        write_finish_entry(archive_p)
    finally:
        entry_free(ent1)

    # Manually allocated entry #2 to confirm freeing the first did not affect
    # the writer's state.
    ent2 = entry_new()
    assert ent2, "archive_entry_new returned NULL"
    try:
        ArchiveEntry(None, ent2).pathname = "manual-2.txt"
        entry_set_filetype(ent2, REGULAR_FILE)
        entry_set_perm(ent2, 0o600)
        entry_set_size(ent2, len(payload_b))
        write_header(archive_p, ent2)
        write_data(archive_p, payload_b, len(payload_b))
        write_finish_entry(archive_p)
    finally:
        entry_free(ent2)

records = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        records.append((entry.pathname, entry.mode & 0o777, b"".join(entry.get_blocks())))

assert records == [
    ("manual-1.txt", 0o644, payload_a),
    ("manual-2.txt", 0o600, payload_b),
], records
print("entry-free", [(n, oct(m)) for n, m, _ in records])
PY
