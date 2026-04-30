#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-iterate-pathname-mtime-single-loop
# @title: python-libarchive-c iterate pathname and mtime in single loop
# @description: Writes a tar archive whose entries each carry an explicit mtime stamped via archive_entry.set_mtime, then walks the archive in a single loop reading both entry.pathname and entry.mtime alongside the payload. Asserts the (name, mtime) pair returned by the reader matches the values written, exercising the wrapped accessors in tandem rather than via separate iteration passes.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-iterate-pathname-mtime-single-loop"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.ffi import (
    REGULAR_FILE,
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    entry_set_mtime,
    write_data,
    write_finish_entry,
    write_header,
)

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "mtimes.tar"
records = [
    ("alpha.txt", b"alpha\n", 1700000000),
    ("beta.txt", b"beta payload\n", 1700001234),
    ("gamma.bin", b"gamma" * 16, 1700099999),
]

with libarchive.file_writer(str(path), "ustar") as writer:
    archive_p = writer._pointer
    for name, payload, mtime in records:
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            entry_set_mtime(ent, mtime, 0)
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

seen = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        # Pull pathname AND mtime in the same iteration step.
        seen.append(
            (
                entry.pathname,
                int(entry.mtime),
                b"".join(entry.get_blocks()),
            )
        )

expected = [(name, mtime, payload) for name, payload, mtime in records]
assert seen == expected, (seen, expected)
print("path-mtime-loop", [(n, m) for n, m, _ in seen])
PY
