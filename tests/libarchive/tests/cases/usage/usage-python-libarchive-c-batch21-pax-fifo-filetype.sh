#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-pax-fifo-filetype
# @title: python-libarchive-c pax FIFO entry roundtrips with isfifo True
# @description: Writes a pax archive containing a single FIFO entry created with entry_set_filetype(S_IFIFO=0o010000) and zero size, then reads it back via file_reader and asserts entry.isfifo is True while isreg/isdir/issym are False, exercising the FIFO filetype branch not covered by existing regular-file/directory/symlink tests.
# @timeout: 120
# @tags: usage, archive, pax, filetype
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
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    write_finish_entry,
    write_header,
)

S_IFIFO = 0o010000

tmpdir = Path(sys.argv[1])
arc = tmpdir / "fifo.pax"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "mypipe"
        entry_set_filetype(ent, S_IFIFO)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

results = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        results.append(
            (entry.pathname, entry.isfifo, entry.isreg, entry.isdir, entry.issym)
        )

assert results == [("mypipe", True, False, False, False)], results
print("pax-fifo", results)
PY
