#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-pax-nanosecond-mtime-roundtrip
# @title: python-libarchive-c pax preserves entry mtime nanosecond component
# @description: Calls entry_set_mtime with seconds=1700000000 and nsec=123456789, writes a pax archive, and asserts the read-back archive_entry_mtime_nsec returns exactly 123456789 alongside the seconds value, exercising the pax extended-header subsecond mtime field beyond the integer-second cases in earlier batches.
# @timeout: 120
# @tags: usage, archive, pax, mtime, nanosecond
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import ctypes
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.ffi import (
    REGULAR_FILE,
    entry_set_filetype,
    entry_set_mtime,
    entry_set_perm,
    entry_set_size,
    write_finish_entry,
    write_header,
)

so = ctypes.CDLL("libarchive.so.13")
mtime_nsec = so.archive_entry_mtime_nsec
mtime_nsec.argtypes = [ctypes.c_void_p]
mtime_nsec.restype = ctypes.c_long

tmpdir = Path(sys.argv[1])
arc = tmpdir / "subsec.pax"
target_sec, target_nsec = 1700000000, 123456789

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "subsec.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        entry_set_mtime(ent, target_sec, target_nsec)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

results = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        m = entry.mtime
        sec = m[0] if isinstance(m, tuple) else int(m)
        nsec = mtime_nsec(entry._entry_p)
        results.append((entry.pathname, sec, nsec))

assert results == [("subsec.txt", target_sec, target_nsec)], results
print("pax-nanosec", results)
PY
