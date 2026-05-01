#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-extract-secure-nodotdot
# @title: python-libarchive-c extract refuses parent-traversal with SECURE_NODOTDOT
# @description: Builds a tar archive containing a benign entry plus a malicious "../escape.txt" entry, then calls libarchive.extract_file with EXTRACT_SECURE_NODOTDOT|EXTRACT_PERM. Asserts the safe entry materialises inside the destination, the traversal entry is rejected with libarchive.exception.ArchiveError, and that no escape.txt file is created in the destination's parent directory. Exercises libarchive's path-sanitisation flag distinct from EXTRACT_SECURE_NOABSOLUTEPATHS.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-extract-secure-nodotdot"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.exception import ArchiveError
from libarchive.extract import EXTRACT_PERM, EXTRACT_SECURE_NODOTDOT
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

archive_path = tmpdir / "with-escape.tar"
entries = [
    ("safe.txt", b"safe payload\n"),
    ("../escape.txt", b"would-escape payload\n"),
]
with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    archive_p = writer._pointer
    for name, body in entries:
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(body))
            write_header(archive_p, ent)
            write_data(archive_p, body, len(body))
            write_finish_entry(archive_p)

dest = tmpdir / "extract-root"
dest.mkdir()
prev = Path.cwd()
raised = False
os.chdir(dest)
try:
    try:
        libarchive.extract_file(
            str(archive_path),
            flags=EXTRACT_PERM | EXTRACT_SECURE_NODOTDOT,
        )
    except ArchiveError as exc:
        raised = True
        msg = str(exc).lower()
        assert ".." in msg or "secur" in msg, msg
finally:
    os.chdir(prev)

assert raised, "expected ArchiveError on '..' entry with SECURE_NODOTDOT"
assert (dest / "safe.txt").read_bytes() == b"safe payload\n"
# Sibling next to dest must not have been created.
assert not (tmpdir / "escape.txt").exists(), sorted(p.name for p in tmpdir.iterdir())
print("secure-nodotdot", sorted(p.name for p in dest.iterdir()))
PY
