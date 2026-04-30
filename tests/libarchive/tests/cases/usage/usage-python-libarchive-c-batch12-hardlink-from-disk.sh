#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-hardlink-from-disk
# @title: python-libarchive-c hardlink from disk
# @description: Writes a tar archive containing a regular file plus a hardlink entry pointing back to it via libarchive's C ABI, then reads it back through python-libarchive-c and verifies islnk is True with linkname pointing at the original.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-hardlink-from-disk"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage"
printf 'shared payload\n' >"$stage/orig.txt"
ln "$stage/orig.txt" "$stage/dup.txt"

python3 - <<'PY' "$tmpdir" "$stage"
import ctypes
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.ffi import (
    REGULAR_FILE, entry_set_size, entry_set_filetype, entry_set_perm,
    write_header, write_data, write_finish_entry,
)

# archive_entry_set_hardlink isn't wrapped by python-libarchive-c, so reach
# into libarchive's C ABI directly to build the hardlink entry.
libarchive_so = ctypes.CDLL("libarchive.so.13")
archive_entry_set_hardlink = libarchive_so.archive_entry_set_hardlink
archive_entry_set_hardlink.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
archive_entry_set_hardlink.restype = None

tmpdir = Path(sys.argv[1])
stage = Path(sys.argv[2])

orig_payload = (stage / "orig.txt").read_bytes()
archive_path = tmpdir / "with-hardlink.tar"

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    archive_p = writer._pointer

    # Regular file entry for orig.txt with the real payload.
    with new_archive_entry() as e1:
        ArchiveEntry(None, e1).pathname = "stage/orig.txt"
        entry_set_filetype(e1, REGULAR_FILE)
        entry_set_perm(e1, 0o644)
        entry_set_size(e1, len(orig_payload))
        write_header(archive_p, e1)
        write_data(archive_p, orig_payload, len(orig_payload))
        write_finish_entry(archive_p)

    # Hardlink entry for dup.txt -> orig.txt, no body.
    with new_archive_entry() as e2:
        ArchiveEntry(None, e2).pathname = "stage/dup.txt"
        entry_set_filetype(e2, REGULAR_FILE)
        entry_set_perm(e2, 0o644)
        entry_set_size(e2, 0)
        archive_entry_set_hardlink(e2, b"stage/orig.txt")
        write_header(archive_p, e2)
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        records.append((entry.pathname.lstrip("/"), entry.islnk, entry.linkname or ""))
        b"".join(entry.get_blocks())

hardlinks = [r for r in records if r[1]]
assert hardlinks, records
assert any(r[2].endswith("orig.txt") for r in hardlinks), records
assert any(r[0].endswith("orig.txt") for r in records), records
print("hardlink", len(records), hardlinks)
PY
