#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-archive-entry-clear-reuse
# @title: python-libarchive-c archive_entry_clear reuse on writer
# @description: Reuses a single archive_entry pointer across two writes by calling archive_entry_clear via ctypes between them, then verifies the resulting tar contains both entries with their respective independent paths and sizes.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-archive-entry-clear-reuse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import ctypes
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
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

# archive_entry_clear isn't wrapped by python-libarchive-c 2.9; pull it from
# libarchive.so.13 directly. It returns the same archive_entry* it was given,
# now reset to defaults so we can repopulate and reuse it.
libarchive_so = ctypes.CDLL("libarchive.so.13")
archive_entry_clear = libarchive_so.archive_entry_clear
archive_entry_clear.argtypes = [ctypes.c_void_p]
archive_entry_clear.restype = ctypes.c_void_p

path = tmpdir / "reuse.tar"
payload_a = b"first payload\n"
payload_b = b"second longer payload bytes\n"

with libarchive.file_writer(str(path), "ustar") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        # First entry.
        ArchiveEntry(None, ent).pathname = "first.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload_a))
        write_header(archive_p, ent)
        write_data(archive_p, payload_a, len(payload_a))
        write_finish_entry(archive_p)

        # Reset the same archive_entry* and reuse it for entry #2.
        archive_entry_clear(ent)

        ArchiveEntry(None, ent).pathname = "second.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o600)
        entry_set_size(ent, len(payload_b))
        write_header(archive_p, ent)
        write_data(archive_p, payload_b, len(payload_b))
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        data = b"".join(entry.get_blocks())
        records.append((entry.pathname, entry.mode & 0o777, data))

assert records == [
    ("first.txt", 0o644, payload_a),
    ("second.txt", 0o600, payload_b),
], records
print("entry-clear-reuse", [(name, oct(mode)) for name, mode, _ in records])
PY
