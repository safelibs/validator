#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-pax-uname-roundtrip-explicit
# @title: python-libarchive-c pax entry preserves an explicit uname string set via ctypes
# @description: Builds a pax_restricted archive on disk where each entry's uname is set to a deterministic label using archive_entry_set_uname through ctypes against libarchive.so.13, reads back via file_reader and ctypes archive_entry_uname, and asserts every recovered uname matches the writer's label, exercising the pax extended-attribute persistence path.
# @timeout: 120
# @tags: usage, archive, pax, uname, r18
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

path = tmpdir / "names.pax"
records = [
    ("paxone.txt", b"r18 pax payload one\n", b"r18userA"),
    ("paxtwo.txt", b"r18 pax payload two with bytes\n", b"r18userB"),
]

with libarchive.file_writer(str(path), "pax_restricted") as writer:
    archive_p = writer._pointer
    for name, payload, uname in records:
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            set_uname(ent, uname)
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

got = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        got[entry.pathname] = get_uname(entry._entry_p)
        b"".join(entry.get_blocks())

for name, _payload, uname in records:
    assert got[name] == uname, (name, got[name], uname)
print("pax-uname-roundtrip-ok", got)
PY
