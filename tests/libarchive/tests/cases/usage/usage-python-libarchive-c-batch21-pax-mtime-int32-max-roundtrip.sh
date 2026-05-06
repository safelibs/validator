#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-pax-mtime-int32-max-roundtrip
# @title: python-libarchive-c pax mtime survives at exact int32 max boundary
# @description: Sets entry mtime to 2147483647 (the maximum signed 32-bit value, the last second before the year-2038 rollover) via entry_set_mtime, writes a pax archive, and asserts the read-back mtime equals 2147483647 exactly. Distinct from the batch20 2030-mtime case because it pins the precise int32 boundary without crossing it.
# @timeout: 120
# @tags: usage, archive, pax, mtime, boundary
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
    write_finish_entry,
    write_header,
)

INT32_MAX = 2147483647

tmpdir = Path(sys.argv[1])
arc = tmpdir / "boundary.pax"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "boundary.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, 0)
        entry_set_mtime(ent, INT32_MAX, 0)
        write_header(archive_p, ent)
        write_finish_entry(archive_p)

mtimes = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        m = entry.mtime
        sec = m[0] if isinstance(m, tuple) else m
        mtimes.append((entry.pathname, sec))

assert mtimes == [("boundary.txt", INT32_MAX)], mtimes
print("pax-int32-max", mtimes)
PY
