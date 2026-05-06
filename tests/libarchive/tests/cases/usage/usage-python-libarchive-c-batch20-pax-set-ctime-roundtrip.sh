#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-pax-set-ctime-roundtrip
# @title: python-libarchive-c pax ctime via ctypes round trip
# @description: Sets archive_entry_set_ctime on a pax entry through ctypes against libarchive.so.13 (libarchive_c 2.9 does not wrap it), writes the archive, then uses archive_entry_ctime via ctypes on read to verify the stored creation/inode-change time round trips at second precision. Pax extended headers are the standard carrier for ctime so the format choice matters.
# @timeout: 120
# @tags: usage, archive, pax, ctime
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
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

tmpdir = Path(sys.argv[1])

so = ctypes.CDLL("libarchive.so.13")
set_ctime = so.archive_entry_set_ctime
set_ctime.argtypes = [ctypes.c_void_p, ctypes.c_int64, ctypes.c_long]
set_ctime.restype = None
get_ctime = so.archive_entry_ctime
get_ctime.argtypes = [ctypes.c_void_p]
get_ctime.restype = ctypes.c_int64

arc = tmpdir / "ctime.pax"
payload = b"timed\n"
target_sec = 1717171717

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "ctime.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        set_ctime(ent, target_sec, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

ctimes = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        ctimes.append((entry.pathname, get_ctime(entry._entry_p)))
        b"".join(entry.get_blocks())

assert ctimes == [("ctime.txt", target_sec)], ctimes
print("pax-ctime", ctimes)
PY
