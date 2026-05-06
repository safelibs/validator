#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-pax-hardlink-target-ctypes
# @title: python-libarchive-c pax hardlink target survives via archive_entry_set_hardlink
# @description: Writes a pax archive containing one regular file and one hardlink entry whose target is set via archive_entry_set_hardlink reached through ctypes, then asserts the read-back hardlink entry reports islnk True with linkname equal to the original pathname. Distinct from the symlink ctypes case in batch18 since it tests the hardlink accessor.
# @timeout: 180
# @tags: usage, archive, pax, hardlink
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
set_hardlink = so.archive_entry_set_hardlink
set_hardlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_hardlink.restype = None

arc = tmpdir / "hardlink.pax"
payload = b"original-bytes\n"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "orig.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "hardlink.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        set_hardlink(ent, b"orig.txt")
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

results = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        results[entry.pathname] = (entry.islnk, entry.issym, entry.linkname)

assert results["orig.txt"] == (False, False, None), results["orig.txt"]
assert results["hardlink.txt"] == (True, False, "orig.txt"), results["hardlink.txt"]
print("pax-hardlink", sorted(results))
PY
