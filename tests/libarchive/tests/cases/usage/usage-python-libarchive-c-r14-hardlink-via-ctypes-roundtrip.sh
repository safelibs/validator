#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-hardlink-via-ctypes-roundtrip
# @title: python-libarchive-c writes a hardlink entry via ctypes archive_entry_set_hardlink
# @description: Uses ctypes to call archive_entry_set_hardlink against libarchive.so.13, builds a pax archive with a regular file plus a hardlink entry pointing to it, reads it back and asserts entry.islnk is True with linkname matching the original and the regular entry exists with the expected payload.
# @timeout: 120
# @tags: usage, archive, pax, hardlink, ctypes
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

_so = ctypes.CDLL("libarchive.so.13")
archive_entry_set_hardlink = _so.archive_entry_set_hardlink
archive_entry_set_hardlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
archive_entry_set_hardlink.restype = None

tmpdir = Path(sys.argv[1])
arc = tmpdir / "hard.pax"
payload = b"hardlink original payload\n"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer

    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "original.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "alias.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        archive_entry_set_hardlink(ent, b"original.txt")
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        records.append(
            (entry.pathname, entry.islnk, entry.linkname or "", b"".join(entry.get_blocks()))
        )

assert len(records) == 2, records
orig_name, orig_islnk, orig_link, orig_body = records[0]
alias_name, alias_islnk, alias_link, alias_body = records[1]
assert orig_name == "original.txt", records
assert orig_islnk is False, records
assert orig_body == payload, len(orig_body)
assert alias_name == "alias.txt", records
assert alias_islnk is True, records
assert alias_link == "original.txt", records
print("hardlink", records[0][:3], records[1][:3])
PY
