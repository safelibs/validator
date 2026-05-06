#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-pax-utf8-uname-ctypes
# @title: python-libarchive-c pax UTF-8 uname round trip via ctypes
# @description: Sets archive_entry_set_uname on a pax entry to a non-ASCII UTF-8 byte sequence (Greek letters) through ctypes against libarchive.so.13, since libarchive_c 2.9 does not wrap that setter. Pax extended headers are the standard carrier for non-ASCII owner names. Reads the entry back and asserts archive_entry_uname returns the same bytes via ctypes.
# @timeout: 120
# @tags: usage, archive, pax, utf8
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
set_uname = so.archive_entry_set_uname
set_uname.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_uname.restype = None
get_uname = so.archive_entry_uname
get_uname.argtypes = [ctypes.c_void_p]
get_uname.restype = ctypes.c_char_p

arc = tmpdir / "uname.pax"
payload = b"owned\n"
uname_utf8 = "αβγ".encode("utf-8")

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "owned.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        set_uname(ent, uname_utf8)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, get_uname(entry._entry_p)))
        b"".join(entry.get_blocks())

assert seen == [("owned.txt", uname_utf8)], seen
print("pax-utf8-uname", seen)
PY
