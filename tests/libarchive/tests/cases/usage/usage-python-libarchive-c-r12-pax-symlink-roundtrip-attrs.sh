#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-pax-symlink-roundtrip-attrs
# @title: python-libarchive-c pax symlink entry exposes issym and linkname
# @description: Writes a pax archive containing a single symlink entry via the entry_set_symlink ctypes accessor and verifies the read-back entry reports issym True with linkname pointing at the expected target while islnk and isreg are False.
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
    SYMBOLIC_LINK,
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    write_finish_entry,
    write_header,
)

tmpdir = Path(sys.argv[1])
arc = tmpdir / "sym.pax"

so = ctypes.CDLL("libarchive.so.13")
set_symlink = so.archive_entry_set_symlink
set_symlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_symlink.restype = None

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "link.txt"
        entry_set_filetype(ent, SYMBOLIC_LINK)
        entry_set_perm(ent, 0o777)
        entry_set_size(ent, 0)
        set_symlink(ent, b"target.txt")
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

results = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        results[entry.pathname] = (entry.issym, entry.islnk, entry.isreg, entry.linkname)

assert results == {"link.txt": (True, False, False, "target.txt")}, results
print("pax-symlink", results)
PY
