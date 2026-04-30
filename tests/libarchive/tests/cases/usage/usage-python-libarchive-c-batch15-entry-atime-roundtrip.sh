#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-entry-atime-roundtrip
# @title: python-libarchive-c entry atime roundtrip via ctypes
# @description: Writes a pax archive whose entries carry an explicit atime stamped through libarchive.so.13 archive_entry_set_atime (libarchive_c 2.9 does not expose an atime setter on ArchiveEntry). Reads each entry back and asserts entry.atime equals the value originally written. pax is used because ustar lacks the extended-header records needed to preserve atime through the round trip.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-entry-atime-roundtrip"
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

so = ctypes.CDLL("libarchive.so.13")
set_atime = so.archive_entry_set_atime
set_atime.argtypes = [ctypes.c_void_p, ctypes.c_int64, ctypes.c_long]
set_atime.restype = None
set_mtime = so.archive_entry_set_mtime
set_mtime.argtypes = [ctypes.c_void_p, ctypes.c_int64, ctypes.c_long]
set_mtime.restype = None

archive_path = tmpdir / "atime.pax"
plan = {
    "first.txt": (b"first payload\n", 1_650_000_000),
    "second.txt": (b"second payload\n", 1_660_000_000),
}

with libarchive.file_writer(str(archive_path), "pax") as writer:
    archive_p = writer._pointer
    for name, (payload, atime_value) in plan.items():
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            # mtime is set so libarchive doesn't fall back to the current
            # clock and pollute the readback comparison.
            set_mtime(ent, atime_value, 0)
            set_atime(ent, atime_value, 0)
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = int(entry.atime)
        b"".join(entry.get_blocks())

for name, (_, atime_value) in plan.items():
    assert got.get(name) == atime_value, (name, got.get(name), atime_value)
print("atime", got)
PY
