#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-tar-zstd-mode-mtime-roundtrip
# @title: python-libarchive-c ustar+zstd preserves mode and mtime
# @description: Writes a ustar+zstd archive whose entry has perm 0o604 and mtime 1700000000 set via ctypes, then asserts file_reader returns those values exactly through the zstd filter chain.
# @timeout: 120
# @tags: usage, archive, tar, zstd, attributes
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
    entry_set_mtime,
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
arc = tmpdir / "mm.tar.zst"
payload = b"mode-mtime tar.zst payload\n"
target_mtime = 1_700_000_000
target_perm = 0o604

with libarchive.file_writer(str(arc), "ustar", "zstd") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "mm.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, target_perm)
        entry_set_size(ent, len(payload))
        entry_set_mtime(ent, target_mtime, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

assert arc.read_bytes()[:4] == b"\x28\xb5\x2f\xfd"

records = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        ptr = entry._entry_p
        records.append((entry.pathname, _get_perm(ptr), entry.mtime,
                        b"".join(entry.get_blocks())))

assert records == [("mm.txt", target_perm, target_mtime, payload)], records
print("zstd-mode-mtime", oct(records[0][1]), records[0][2])
PY
