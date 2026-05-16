#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-pax-uid-zero-roundtrip
# @title: python-libarchive-c pax entry with uid=0 (root) survives roundtrip via ctypes setter
# @description: Writes a pax entry whose uid is set to 0 (root) via archive_entry_set_uid reached through ctypes (python-libarchive-c does not expose a uid kwarg setter), then reads back the entry.uid attribute and asserts the value is 0, exercising the pax uid=0 ctypes-driven roundtrip distinct from the existing r20 pax-uid-1234-roundtrip case which used a non-zero uid.
# @timeout: 60
# @tags: usage, archive, pax, uid, r21
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
    write_finish_entry,
    write_header,
)

tmpdir = Path(sys.argv[1])

so = ctypes.CDLL("libarchive.so.13")
set_uid = so.archive_entry_set_uid
set_uid.argtypes = [ctypes.c_void_p, ctypes.c_int64]
set_uid.restype = None

arc = tmpdir / "uid.pax"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "u.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        set_uid(ent, 0)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

uids = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        uids.append(entry.uid)

assert uids == [0], uids
print("pax-uid-0-ok", uids[0])
PY
