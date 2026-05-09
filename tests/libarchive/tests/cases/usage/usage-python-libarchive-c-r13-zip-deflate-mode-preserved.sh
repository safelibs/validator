#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-zip-deflate-mode-preserved
# @title: python-libarchive-c zip+deflate preserves entry permission bits via ctypes
# @description: Writes a zip+deflate archive whose entry has perm 0o750 set through ctypes archive_entry_set_perm and confirms that file_reader returns entry.perm == 0o750 on read-back, exercising mode preservation in the deflate path.
# @timeout: 120
# @tags: usage, archive, zip, deflate, perm
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

# r5.2-1build1's python wrapper drops ArchiveEntry.perm; read it via the C
# accessor against the entry's internal pointer.
_so = ctypes.CDLL("libarchive.so.13")
_get_perm = _so.archive_entry_perm
_get_perm.argtypes = [ctypes.c_void_p]
_get_perm.restype = ctypes.c_int

tmpdir = Path(sys.argv[1])
arc = tmpdir / "modes.zip"
payload = b"perm-preserve payload\n"

# zip embeds deflate as its native compression; libarchive rejects "deflate"
# as a separate filter for the zip format, so call file_writer without one.
with libarchive.file_writer(str(arc), "zip") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "secret.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o750)
        entry_set_size(ent, len(payload))
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        records.append((entry.pathname, _get_perm(entry._entry_p),
                        b"".join(entry.get_blocks())))

assert records == [("secret.txt", 0o750, payload)], records
print("zip-perm-roundtrip", oct(records[0][1]))
PY
