#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-pax-symlink-linkpath
# @title: python-libarchive-c pax symlink linkpath round trip
# @description: Writes a pax archive containing a symlink entry whose target is set via archive_entry_set_symlink (reached through ctypes since python-libarchive-c does not wrap it directly). Reads the archive back and asserts the entry's issym is True, both ArchiveEntry.linkname and ArchiveEntry.linkpath expose the same target string, and entry.linkpath equals the bytes that were stamped onto the entry. Exercises the symlink-target accessor distinct from the hardlink-target path covered by earlier batches.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-pax-symlink-linkpath"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import ctypes
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.ffi import (
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    write_finish_entry,
    write_header,
)

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

S_IFLNK = 0o120000

so = ctypes.CDLL("libarchive.so.13")
set_symlink = so.archive_entry_set_symlink
set_symlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_symlink.restype = None

archive_path = tmpdir / "links.pax"
links = {
    "shortlink": b"target/file.txt",
    "deeper/longlink": b"../../shared/resource/path.bin",
}

with libarchive.file_writer(str(archive_path), "pax") as writer:
    archive_p = writer._pointer
    for name, target in links.items():
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, S_IFLNK)
            entry_set_perm(ent, 0o777)
            entry_set_size(ent, 0)
            set_symlink(ent, target)
            write_header(archive_p, ent)
            write_finish_entry(archive_p)

results = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        results[entry.pathname] = (
            entry.issym,
            entry.islnk,
            entry.linkname,
            entry.linkpath,
        )

for name, target_bytes in links.items():
    assert name in results, (name, sorted(results.keys()))
    issym, islnk, linkname, linkpath = results[name]
    target_str = target_bytes.decode("ascii")
    assert issym is True, (name, issym)
    assert islnk is False, (name, islnk)  # hardlink-only
    assert linkname == target_str, (name, linkname, target_str)
    # python-libarchive-c exposes the same value through both attributes.
    assert linkpath == linkname, (name, linkpath, linkname)
print("pax-symlink", sorted(results))
PY
