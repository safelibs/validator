#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-tar-mtime-zero-roundtrip
# @title: python-libarchive-c tar mtime=0 round trip
# @description: Writes a ustar archive whose entries explicitly carry mtime=0 (epoch) via libarchive.ffi.entry_set_mtime, reads the archive back, and asserts every entry's mtime is exactly 0 on read. Exercises the corner case where the timestamp field is the zero sentinel but must still round trip rather than being treated as "unset".
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-tar-mtime-zero-roundtrip"
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
    entry_set_mtime,
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "mtime-zero.tar"
plan = {
    "first.txt": b"first payload\n",
    "second.txt": b"second payload bytes\n",
    "third.bin": bytes(range(64)),
}

with libarchive.file_writer(str(path), "ustar") as writer:
    archive_p = writer._pointer
    for name, payload in plan.items():
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            entry_set_mtime(ent, 0, 0)
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

times = {}
payloads = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        # entry.mtime may be an int (seconds) or a (sec, nsec) tuple
        # depending on libarchive_c version; normalize to seconds.
        m = entry.mtime
        if isinstance(m, tuple):
            sec = m[0]
        else:
            sec = m
        times[entry.pathname] = sec
        payloads[entry.pathname] = b"".join(entry.get_blocks())

assert sorted(times.keys()) == sorted(plan.keys()), times
for name, payload in plan.items():
    assert payloads[name] == payload, (name, len(payloads[name]))
    sec = times[name]
    assert sec == 0, (name, sec)
print("mtime-zero", times)
PY
