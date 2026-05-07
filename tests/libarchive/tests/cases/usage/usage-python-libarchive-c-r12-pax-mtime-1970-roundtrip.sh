#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-pax-mtime-1970-roundtrip
# @title: python-libarchive-c pax mtime epoch zero roundtrip
# @description: Writes a pax archive with entry_set_mtime(0, 0) and asserts the read-back entry.mtime is exactly 0, exercising the epoch-boundary mtime value distinct from the existing 2030 and int32-max mtime cases.
# @timeout: 120
# @tags: usage, archive, pax, mtime
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
    write_data,
    write_finish_entry,
    write_header,
)

tmpdir = Path(sys.argv[1])
arc = tmpdir / "epoch.pax"
payload = b"epoch zero\n"

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "epoch.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        entry_set_mtime(ent, 0, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

times = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        times.append((entry.pathname, entry.mtime))
        b"".join(entry.get_blocks())

assert times == [("epoch.txt", 0)], times
print("pax-epoch", times)
PY
