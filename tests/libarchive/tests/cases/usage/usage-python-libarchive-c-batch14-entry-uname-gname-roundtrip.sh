#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-entry-uname-gname-roundtrip
# @title: python-libarchive-c entry uname/gname strings preserved
# @description: Sets archive_entry_set_uname / archive_entry_set_gname via ctypes against libarchive.so.13 (libarchive_c 2.9 does not wrap them), writes a ustar archive, then reads the entries back and uses archive_entry_uname / archive_entry_gname through ctypes to verify the symbolic owner names round trip, alongside numeric uid/gid which the python binding does expose.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-entry-uname-gname-roundtrip"
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
set_uname = so.archive_entry_set_uname
set_uname.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_uname.restype = None
set_gname = so.archive_entry_set_gname
set_gname.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_gname.restype = None
get_uname = so.archive_entry_uname
get_uname.argtypes = [ctypes.c_void_p]
get_uname.restype = ctypes.c_char_p
get_gname = so.archive_entry_gname
get_gname.argtypes = [ctypes.c_void_p]
get_gname.restype = ctypes.c_char_p
set_uid = so.archive_entry_set_uid
set_uid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
set_uid.restype = None
set_gid = so.archive_entry_set_gid
set_gid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
set_gid.restype = None

path = tmpdir / "names.tar"
records = [
    ("alpha.txt", b"alpha\n", 1000, 1000, b"alice", b"crew"),
    ("beta.txt", b"beta payload\n", 1234, 5678, b"bob", b"ops"),
]

with libarchive.file_writer(str(path), "ustar") as writer:
    archive_p = writer._pointer
    for name, payload, uid, gid, uname, gname in records:
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            set_uid(ent, uid)
            set_gid(ent, gid)
            set_uname(ent, uname)
            set_gname(ent, gname)
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

seen = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        ent_p = entry._entry_p
        seen[entry.pathname] = (
            entry.uid,
            entry.gid,
            get_uname(ent_p),
            get_gname(ent_p),
            b"".join(entry.get_blocks()),
        )

for name, payload, uid, gid, uname, gname in records:
    got = seen[name]
    assert got == (uid, gid, uname, gname, payload), (name, got)
print("uname-gname", {n: (s[0], s[1], s[2], s[3]) for n, s in seen.items()})
PY
