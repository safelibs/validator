#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-tar-long-linkname
# @title: python-libarchive-c gnutar long symlink target
# @description: Writes a gnutar archive whose symlink entry carries a target path far longer than the 100-byte ustar linkname field, forcing libarchive to emit a GNU LongLink K-type header to carry the full target. Reads the archive back and asserts the symlink's linkname round trips byte-for-byte, which can only happen if the LongLink extension is being honored on both encode and decode.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-tar-long-linkname"
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

# AE_IFLNK / S_IFLNK — symbolic-link filetype bits in libarchive's entry mode.
SYMBOLIC_LINK = 0o120000

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# archive_entry_set_symlink isn't exported by libarchive_c, reach into so.13.
so = ctypes.CDLL("libarchive.so.13")
set_symlink = so.archive_entry_set_symlink
set_symlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
set_symlink.restype = None

archive_path = tmpdir / "longlink.tar"
target = "/".join(["seg" + str(i).zfill(3) for i in range(40)]) + "/final.txt"
assert len(target) > 200, len(target)

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "link"
        entry_set_filetype(ent, SYMBOLIC_LINK)
        entry_set_perm(ent, 0o777)
        entry_set_size(ent, 0)
        set_symlink(ent, target.encode("utf-8"))
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

# The raw tar must contain a "././@LongLink" GNU extension header carrying the
# full target string so that downstream decoders can recover the long path.
raw = archive_path.read_bytes()
assert b"@LongLink" in raw, raw[:512]
assert target.encode("utf-8") in raw, target

found = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        found.append((entry.pathname, entry.issym, entry.linkname or ""))

assert any(r[1] and r[2] == target for r in found), found
print("long-linkname", len(target))
PY
