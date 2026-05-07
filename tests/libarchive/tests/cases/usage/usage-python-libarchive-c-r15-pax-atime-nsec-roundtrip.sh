#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-pax-atime-nsec-roundtrip
# @title: python-libarchive-c entry atime nanosecond field round trips through pax
# @description: Sets entry atime to (1650000000 seconds, 987654321 nanoseconds) via libarchive.so.13 archive_entry_set_atime through ctypes, writes a pax archive (the standard format that preserves sub-second timestamps via extended-header records), then reads back the entry and asserts the seconds component recovered through entry.atime equals 1650000000 and the nanoseconds component recovered through archive_entry_atime_nsec equals 987654321 — pinning sub-second atime precision distinct from the batch21 mtime-only nanosecond case.
# @timeout: 120
# @tags: usage, archive, pax, atime, nanosecond
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

tmpdir = Path(sys.argv[1])

so = ctypes.CDLL("libarchive.so.13")
set_atime = so.archive_entry_set_atime
set_atime.argtypes = [ctypes.c_void_p, ctypes.c_int64, ctypes.c_long]
set_atime.restype = None
get_atime_nsec = so.archive_entry_atime_nsec
get_atime_nsec.argtypes = [ctypes.c_void_p]
get_atime_nsec.restype = ctypes.c_long

target_sec = 1650000000
target_nsec = 987654321

arc = tmpdir / "atime-nsec.pax"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "atime-nsec.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        # Pin both mtime and atime to the same (sec,nsec) so libarchive does
        # not fall back to a current-time atime when mtime is the only stamp.
        entry_set_mtime(ent, target_sec, target_nsec)
        set_atime(ent, target_sec, target_nsec)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        records.append(
            (
                entry.pathname,
                int(entry.atime),
                int(get_atime_nsec(entry._entry_p)),
            )
        )
        b"".join(entry.get_blocks())

assert records == [("atime-nsec.txt", target_sec, target_nsec)], records
print("pax-atime-nsec", records)
PY
