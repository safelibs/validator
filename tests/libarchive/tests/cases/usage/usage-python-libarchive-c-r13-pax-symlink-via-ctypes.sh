#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-pax-symlink-via-ctypes
# @title: python-libarchive-c pax symlink entry built via ctypes filetype constant
# @description: Writes a pax archive containing a symlink entry by invoking entry_set_filetype with the integer SYMBOLIC_LINK constant 0o120000 (libarchive.ffi does not export a SYMBOLIC_LINK alias), then reads it back and asserts entry.issym is True with linkname pointing at the expected target.
# @timeout: 120
# @tags: usage, archive, pax, symlink
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
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    write_finish_entry,
    write_header,
)

# archive_entry_set_symlink isn't wrapped in 2.x; reach into libarchive.so.13.
_so = ctypes.CDLL("libarchive.so.13")
archive_entry_set_symlink = _so.archive_entry_set_symlink
archive_entry_set_symlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
archive_entry_set_symlink.restype = None

SYMBOLIC_LINK = 0o120000  # S_IFLNK; libarchive.ffi has no alias on noble.

tmpdir = Path(sys.argv[1])
arc = tmpdir / "sym.pax"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "link"
        entry_set_filetype(ent, SYMBOLIC_LINK)
        entry_set_perm(ent, 0o777)
        entry_set_size(ent, 0)
        archive_entry_set_symlink(ent, b"target.txt")
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        records.append((entry.pathname, entry.issym, entry.linkname or ""))

assert len(records) == 1, records
name, issym, linkname = records[0]
assert name == "link", records
assert issym is True, records
assert linkname == "target.txt", records
print("pax-symlink", records)
PY
