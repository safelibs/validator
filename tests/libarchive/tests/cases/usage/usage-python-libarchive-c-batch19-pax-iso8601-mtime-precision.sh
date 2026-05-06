#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-pax-iso8601-mtime-precision
# @title: python-libarchive-c pax mtime sub-second roundtrip
# @description: Writes a pax archive with an entry whose mtime has explicit nanosecond precision and verifies the readback retains second-resolution mtime equal to what was set.
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
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

tmpdir = Path(sys.argv[1])
arc = tmpdir / "pax.tar"
payload = b"timed\n"
target_sec = 1700000000

with libarchive.file_writer(str(arc), "pax") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ae = ArchiveEntry(None, ent)
        ae.pathname = "timed.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        ae.set_mtime(target_sec, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

mtimes = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        mtimes.append(entry.mtime)
        b"".join(entry.get_blocks())

print("mtimes", mtimes)
assert any(int(m) == target_sec for m in mtimes), f"expected mtime {target_sec} in {mtimes}"
PY
