#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-entry-type-flags-mixed
# @title: python-libarchive-c entry isreg/isdir/isfifo/issym flags
# @description: Builds a pax archive containing one regular file, one directory, one fifo, and one symbolic link (filetype bits stamped via archive_entry_set_filetype, with set_symlink supplied through ctypes for the link target). Reads every entry back and asserts entry.isreg, entry.isdir, entry.isfifo, and entry.issym each report True only on the matching entry. Also asserts entry.islnk (which the binding implements as a hardlink check) reports False on the symlink so the two link concepts are not conflated.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-entry-type-flags-mixed"
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

S_IFDIR = 0o040000
S_IFIFO = 0o010000
S_IFLNK = 0o120000

so = ctypes.CDLL("libarchive.so.13")
set_symlink = so.archive_entry_set_symlink
set_symlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_symlink.restype = None

path = tmpdir / "types.pax"
reg_payload = b"regular contents\n"

with libarchive.file_writer(str(path), "pax") as writer:
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
        ArchiveEntry(None, ent).pathname = "subdir/"
        entry_set_filetype(ent, S_IFDIR)
        entry_set_perm(ent, 0o755)
        entry_set_size(ent, 0)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "queue.fifo"
        entry_set_filetype(ent, S_IFIFO)
        entry_set_perm(ent, 0o600)
        entry_set_size(ent, 0)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "link"
        entry_set_filetype(ent, S_IFLNK)
        entry_set_perm(ent, 0o777)
        entry_set_size(ent, 0)
        set_symlink(ent, b"regular.txt")
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

flags = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        flags[entry.pathname.rstrip("/")] = (
            entry.isreg,
            entry.isdir,
            entry.isfifo,
            entry.issym,
            entry.islnk,  # hardlink-only check; should stay False here
        )
        b"".join(entry.get_blocks())

# Exactly one True per attribute across the regular/dir/fifo/sym set.
assert flags["regular.txt"] == (True, False, False, False, False), flags["regular.txt"]
assert flags["subdir"]      == (False, True, False, False, False), flags["subdir"]
assert flags["queue.fifo"]  == (False, False, True, False, False), flags["queue.fifo"]
assert flags["link"]        == (False, False, False, True, False), flags["link"]
print("type-flags", flags)
PY
