#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-entry-uid-gid-mtime-read
# @title: python-libarchive-c entry size+uid+gid+mtime read after write
# @description: Writes a ustar archive whose entry uid/gid/mtime are set explicitly through libarchive's C ABI via ctypes, then verifies size, uid, gid, and mtime roundtrip on read through python-libarchive-c.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-entry-uid-gid-mtime-read"
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

# uid/gid/mtime setters aren't exposed by python-libarchive-c 2.9; reach into
# libarchive.so.13 directly so we can verify the readback path for these
# fields.
libarchive_so = ctypes.CDLL("libarchive.so.13")
archive_entry_set_uid = libarchive_so.archive_entry_set_uid
archive_entry_set_uid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
archive_entry_set_uid.restype = None
archive_entry_set_gid = libarchive_so.archive_entry_set_gid
archive_entry_set_gid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
archive_entry_set_gid.restype = None
archive_entry_set_mtime = libarchive_so.archive_entry_set_mtime
archive_entry_set_mtime.argtypes = [ctypes.c_void_p, ctypes.c_int64, ctypes.c_long]
archive_entry_set_mtime.restype = None

path = tmpdir / "ids.tar"
payload = b"ids payload\n"
target_uid = 1234
target_gid = 5678
target_mtime = 1_700_000_000

with libarchive.file_writer(str(path), "ustar") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "ids.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        archive_entry_set_uid(ent, target_uid)
        archive_entry_set_gid(ent, target_gid)
        archive_entry_set_mtime(ent, target_mtime, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        records.append(
            (entry.pathname, entry.size, entry.uid, entry.gid, int(entry.mtime))
        )
        b"".join(entry.get_blocks())

assert records == [("ids.txt", len(payload), target_uid, target_gid, target_mtime)], records
print("ids-mtime", records)
PY
