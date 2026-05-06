#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-pax-gname-ctypes-roundtrip
# @title: python-libarchive-c pax gname survives via archive_entry_set_gname
# @description: Writes a pax entry whose group name is set to "staff" via archive_entry_set_gname reached through ctypes (python-libarchive-c does not expose a setter), then reads back the gname through archive_entry_gname and asserts byte equality. Distinct from the existing UTF-8 uname ctypes case in batch20 because it tests the gname accessor.
# @timeout: 120
# @tags: usage, archive, pax, gname
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
set_gname = so.archive_entry_set_gname
set_gname.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_gname.restype = None
get_gname = so.archive_entry_gname
get_gname.argtypes = [ctypes.c_void_p]
get_gname.restype = ctypes.c_char_p

arc = tmpdir / "gname.pax"
target_gname = b"staff"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "g.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        set_gname(ent, target_gname)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, get_gname(entry._entry_p)))

assert seen == [("g.txt", target_gname)], seen
print("pax-gname", seen)
PY
