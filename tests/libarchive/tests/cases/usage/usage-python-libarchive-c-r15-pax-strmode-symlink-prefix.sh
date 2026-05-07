#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-pax-strmode-symlink-prefix
# @title: python-libarchive-c ArchiveEntry.strmode renders 'l' leading char on a symlink entry
# @description: Writes a pax archive containing a symlink entry (filetype S_IFLNK, target stamped via archive_entry_set_symlink through ctypes) and a regular file entry, reads them back, and asserts ArchiveEntry.strmode begins with 'l' for the symlink and '-' for the regular file. Exercises the strmode renderer against a non-regular filetype (distinct from the batch16 strmode case which only covers regular files).
# @timeout: 120
# @tags: usage, archive, pax, strmode, symlink
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
S_IFLNK = 0o120000

so = ctypes.CDLL("libarchive.so.13")
set_symlink = so.archive_entry_set_symlink
set_symlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_symlink.restype = None

arc = tmpdir / "strmode-link.pax"
reg_payload = b"r15 strmode regular body\n"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer

    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "regular.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(reg_payload))
        write_header(archive_p, ent)
        write_data(archive_p, reg_payload, len(reg_payload))
        write_finish_entry(archive_p)

    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "link.lnk"
        entry_set_filetype(ent, S_IFLNK)
        entry_set_perm(ent, 0o777)
        entry_set_size(ent, 0)
        set_symlink(ent, b"regular.txt")
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

modes = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        s = entry.strmode
        if isinstance(s, bytes):
            s = s.decode("ascii")
        modes[entry.pathname] = (s, entry.issym, entry.isreg)
        b"".join(entry.get_blocks())

reg_str, reg_sym, reg_isreg = modes["regular.txt"]
lnk_str, lnk_sym, lnk_isreg = modes["link.lnk"]

# strmode is 11 chars (10 + trailing space) on Ubuntu 24.04 libarchive; check the leading type char.
assert reg_str[0] == "-", (reg_str,)
assert reg_isreg is True, modes
assert reg_sym is False, modes

assert lnk_str[0] == "l", (lnk_str,)
assert lnk_sym is True, modes
assert lnk_isreg is False, modes
print("strmode-symlink-prefix", modes)
PY
