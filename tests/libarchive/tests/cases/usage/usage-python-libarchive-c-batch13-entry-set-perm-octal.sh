#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-entry-set-perm-octal
# @title: python-libarchive-c ArchiveEntry set_perm octal verified
# @description: Writes a tar archive whose entry permissions are set explicitly via libarchive.ffi.entry_set_perm with a non-default octal mode and verifies the same low-9 mode bits surface back through entry.mode on read.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-entry-set-perm-octal"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
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

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "perm.tar"
payload = b"perm-bytes\n"
target_mode = 0o640

with libarchive.file_writer(str(path), "ustar") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "permcheck.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, target_mode)
        entry_set_size(ent, len(payload))
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

modes = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        modes.append((entry.pathname, entry.mode & 0o777))
        b"".join(entry.get_blocks())

assert modes == [("permcheck.txt", target_mode)], modes
print("set-perm", oct(target_mode), modes)
PY
