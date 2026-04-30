#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-write-then-extract-modes
# @title: python-libarchive-c extract preserves explicit perm bits
# @description: Builds a ustar archive whose entries are stamped with explicit non-default mode bits via libarchive.ffi, extracts it through libarchive.extract_file with EXTRACT_PERM, and asserts the on-disk modes match the values that were written into the entry headers.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-write-then-extract-modes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import stat
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.extract import EXTRACT_PERM
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

archive_path = tmpdir / "perms.tar"
entries = [
    ("alpha.sh", b"#!/bin/sh\necho a\n", 0o750),
    ("readme.txt", b"readme contents\n", 0o640),
    ("locked.dat", b"locked\n", 0o600),
]

with libarchive.file_writer(str(archive_path), "ustar") as writer:
    archive_p = writer._pointer
    for name, payload, mode in entries:
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, mode)
            entry_set_size(ent, len(payload))
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

dest = tmpdir / "out"
dest.mkdir()
prev = Path.cwd()
old_umask = os.umask(0)
try:
    os.chdir(dest)
    libarchive.extract_file(str(archive_path), flags=EXTRACT_PERM)
finally:
    os.chdir(prev)
    os.umask(old_umask)

for name, payload, mode in entries:
    on_disk = dest / name
    assert on_disk.read_bytes() == payload, name
    actual = stat.S_IMODE(on_disk.stat().st_mode)
    assert actual == mode, (name, oct(actual), oct(mode))
print("extract-modes", [(name, oct(mode)) for name, _, mode in entries])
PY
