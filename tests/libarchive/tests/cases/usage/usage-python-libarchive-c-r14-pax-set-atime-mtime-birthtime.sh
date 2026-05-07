#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-pax-set-atime-mtime-birthtime
# @title: python-libarchive-c sets atime, mtime, and birthtime on a pax entry via ffi
# @description: Builds a pax archive with entry_set_atime, entry_set_mtime, and entry_set_birthtime each set to distinct epoch values via libarchive.ffi, reads the archive back and asserts the entry surfaces the same atime, mtime, and birthtime values, exercising all three time setters in one entry.
# @timeout: 60
# @tags: usage, archive, pax, atime, mtime, birthtime
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
    entry_set_atime,
    entry_set_birthtime,
    entry_set_filetype,
    entry_set_mtime,
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

tmpdir = Path(sys.argv[1])
arc = tmpdir / "times.pax"
payload = b"three timestamps body\n"
atime_v = 1600000001
mtime_v = 1700000002
birth_v = 1500000003

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "times.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        entry_set_atime(ent, atime_v, 0)
        entry_set_mtime(ent, mtime_v, 0)
        entry_set_birthtime(ent, birth_v, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

records = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        records.append((entry.pathname, entry.atime, entry.mtime, entry.birthtime))
        b"".join(entry.get_blocks())

assert len(records) == 1, records
name, atime_r, mtime_r, birth_r = records[0]
assert name == "times.txt", records
assert atime_r == atime_v, records
assert mtime_r == mtime_v, records
assert birth_r == birth_v, records
print("pax-times", records)
PY
