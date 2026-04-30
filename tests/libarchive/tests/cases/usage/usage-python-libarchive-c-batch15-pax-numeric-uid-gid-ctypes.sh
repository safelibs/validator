#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-pax-numeric-uid-gid-ctypes
# @title: python-libarchive-c pax numeric uid+gid via ctypes
# @description: Writes a pax archive whose entries carry numeric uid and gid stamped through libarchive.so.13 archive_entry_set_uid / archive_entry_set_gid (libarchive_c 2.9 does not expose uid/gid setters on ArchiveEntry). Reads each entry back and asserts entry.uid and entry.gid equal the numeric values written. pax preserves arbitrarily large numeric ids in extended-header records, so the test uses values that exceed the ustar octal field width.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-pax-numeric-uid-gid-ctypes"
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
set_uid = so.archive_entry_set_uid
set_uid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
set_uid.restype = None
set_gid = so.archive_entry_set_gid
set_gid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
set_gid.restype = None

archive_path = tmpdir / "ids.pax"
# Values intentionally above the 0o7777777 (2097151) ustar octal limit so the
# pax extended-header records are exercised on the writer and reader sides.
plan = {
    "alpha.txt": (b"alpha payload\n", 9_000_000, 9_000_001),
    "beta.txt": (b"beta payload bytes\n", 12_345_678, 87_654_321),
}

with libarchive.file_writer(str(archive_path), "pax") as writer:
    archive_p = writer._pointer
    for name, (payload, uid, gid) in plan.items():
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            set_uid(ent, uid)
            set_gid(ent, gid)
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

got = {}
payloads = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = (entry.uid, entry.gid)
        payloads[entry.pathname] = b"".join(entry.get_blocks())

for name, (payload, uid, gid) in plan.items():
    assert got.get(name) == (uid, gid), (name, got.get(name), (uid, gid))
    assert payloads.get(name) == payload, (name, len(payloads.get(name, b"")))
print("pax-uid-gid", got)
PY
