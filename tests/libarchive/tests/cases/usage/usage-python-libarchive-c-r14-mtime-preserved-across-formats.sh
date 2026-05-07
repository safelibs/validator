#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-mtime-preserved-across-formats
# @title: python-libarchive-c preserves an explicit mtime through ustar, pax, and gnutar formats
# @description: Writes the same single entry with entry_set_mtime(1700000000, 0) into ustar, pax, and gnutar archives by reaching into libarchive.ffi, then reads each back and asserts entry.mtime is exactly 1700000000 in all three, verifying mtime preservation is consistent across tar dialects.
# @timeout: 90
# @tags: usage, archive, mtime, multi-format
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
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

tmpdir = Path(sys.argv[1])
payload = b"mtime preserve\n"
target_mtime = 1700000000
formats = ("ustar", "pax", "gnutar")

for fmt in formats:
    arc = tmpdir / f"out.{fmt}.tar"
    with libarchive.file_writer(str(arc), fmt) as writer:
        archive_p = writer._pointer
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = "preserved.txt"
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            entry_set_mtime(ent, target_mtime, 0)
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

for fmt in formats:
    arc = tmpdir / f"out.{fmt}.tar"
    seen = []
    with libarchive.file_reader(str(arc)) as archive:
        for entry in archive:
            seen.append((entry.pathname, entry.mtime))
            b"".join(entry.get_blocks())
    assert seen == [("preserved.txt", target_mtime)], (fmt, seen)

print("mtime-preserved", target_mtime)
PY
