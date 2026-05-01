#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-extract-preserve-perm
# @title: python-libarchive-c extract preserves entry permissions
# @description: Builds a tar archive containing a regular file whose stored mode is 0640 (group-readable but not world-readable) and a script-like file with mode 0750. Calls libarchive.extract_file with the EXTRACT_PERM flag set, then stats the on-disk extracted files and asserts each has the exact stored permission bits, confirming the extract pipeline is honoring the explicit perm-restore flag.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-extract-preserve-perm"
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

archive_path = tmpdir / "perm.tar"
plan = [
    ("data.txt", 0o640, b"perm-protected data\n"),
    ("run.sh", 0o750, b"#!/bin/sh\necho hi\n"),
]

with libarchive.file_writer(str(archive_path), "ustar") as writer:
    archive_p = writer._pointer
    for name, mode, payload in plan:
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
# umask must not strip the perm bits we want to validate.
old_umask = os.umask(0o000)
os.chdir(dest)
try:
    libarchive.extract_file(str(archive_path), flags=EXTRACT_PERM)
finally:
    os.chdir(prev)
    os.umask(old_umask)

for name, mode, payload in plan:
    p = dest / name
    assert p.read_bytes() == payload, name
    actual = stat.S_IMODE(p.stat().st_mode)
    assert actual == mode, (name, oct(actual), oct(mode))
print("extract-perm", [(n, oct(m)) for n, m, _ in plan])
PY
