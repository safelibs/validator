#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-pax-mtime-2030-roundtrip
# @title: python-libarchive-c pax preserves mtime within int32 range round trip
# @description: Writes a pax archive whose entry mtime is set to 2030-01-01 UTC (1893456000 seconds, within int32) via libarchive.ffi.entry_set_mtime, then asserts the read-back entry.mtime matches exactly so the pax extended-header path is exercised end to end.
# @timeout: 120
# @tags: usage, archive, pax, mtime
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
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
arc = tmpdir / "twenty30.pax"
payload = b"twenty30\n"
target_sec = 1893456000  # 2030-01-01T00:00:00Z

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "twenty30.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        entry_set_mtime(ent, target_sec, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

mtimes = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        m = entry.mtime
        sec = m[0] if isinstance(m, tuple) else m
        mtimes.append((entry.pathname, sec))
        b"".join(entry.get_blocks())

assert mtimes == [("twenty30.txt", target_sec)], mtimes
print("pax-2030-mtime", mtimes)
PY
