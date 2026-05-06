#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-pax-perm-0700-roundtrip
# @title: python-libarchive-c pax entry permission 0700 roundtrip
# @description: Writes a pax archive whose entry permission is set explicitly to 0o700 via libarchive.ffi.entry_set_perm and asserts the same low-9 mode bits surface back through entry.mode on read. Distinct format+mode combination from existing ustar/0o640 and tar/0o644 perm cases.
# @timeout: 120
# @tags: usage, archive, pax, mode
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
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

tmpdir = Path(sys.argv[1])
arc = tmpdir / "perm0700.pax"
payload = b"private\n"
target_mode = 0o700

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "private.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, target_mode)
        entry_set_size(ent, len(payload))
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

modes = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        modes.append((entry.pathname, entry.mode & 0o777))
        b"".join(entry.get_blocks())

assert modes == [("private.txt", target_mode)], modes
print("pax-perm", oct(target_mode), modes)
PY
