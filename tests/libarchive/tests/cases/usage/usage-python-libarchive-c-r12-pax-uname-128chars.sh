#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-pax-uname-128chars
# @title: python-libarchive-c pax uname accepts a 128-character ASCII name
# @description: Writes a pax archive whose entry uname is a 128-character ASCII string set via entry_set_uname (ctypes), and asserts the read-back uname is exactly that string. Distinct from existing default-empty and short-uname cases.
# @timeout: 120
# @tags: usage, archive, pax, uname
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
arc = tmpdir / "longuname.pax"
payload = b"long uname payload\n"
long_uname = "u" + "a" * 127  # 128 chars
assert len(long_uname) == 128

so = ctypes.CDLL("libarchive.so.13")
set_uname = so.archive_entry_set_uname
set_uname.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_uname.restype = None

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "long-uname.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        set_uname(ent, long_uname.encode("ascii"))
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

unames = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        unames[entry.pathname] = entry.uname
        b"".join(entry.get_blocks())

assert unames == {"long-uname.txt": long_uname}, (unames, long_uname[:16])
print("pax-uname-128", len(long_uname))
PY
