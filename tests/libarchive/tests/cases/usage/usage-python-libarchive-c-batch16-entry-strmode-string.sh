#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-entry-strmode-string
# @title: python-libarchive-c ArchiveEntry.strmode rendering
# @description: Writes a ustar archive whose entries carry a range of explicit permission bits set via libarchive.ffi.entry_set_perm, then reads the archive back and asserts ArchiveEntry.strmode (which wraps archive_entry_strmode) renders the expected ten-character mode string for each entry.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-entry-strmode-string"
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
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "strmode.tar"
plan = [
    ("rw-r--r--.txt", 0o644, b"common644\n"),
    ("rwxr-xr-x.txt", 0o755, b"executable755\n"),
    ("rw-------.txt", 0o600, b"private600\n"),
    ("r--r--r--.txt", 0o444, b"readonly444\n"),
]

with libarchive.file_writer(str(path), "ustar") as writer:
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

def rwx(triplet_bits):
    out = []
    out.append("r" if triplet_bits & 0o4 else "-")
    out.append("w" if triplet_bits & 0o2 else "-")
    out.append("x" if triplet_bits & 0o1 else "-")
    return "".join(out)

def expected_strmode(mode):
    user = rwx((mode >> 6) & 0o7)
    group = rwx((mode >> 3) & 0o7)
    other = rwx(mode & 0o7)
    # Regular file leading char is '-'.
    return "-" + user + group + other

seen = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        s = entry.strmode
        if isinstance(s, bytes):
            s = s.decode("ascii")
        seen.append((entry.pathname, entry.mode & 0o777, s))
        b"".join(entry.get_blocks())

assert len(seen) == len(plan), seen
for (got_name, got_mode, got_str), (exp_name, exp_mode, _) in zip(seen, plan):
    assert got_name == exp_name, (got_name, exp_name)
    assert got_mode == exp_mode, (oct(got_mode), oct(exp_mode))
    want = expected_strmode(exp_mode)
    assert got_str == want, (got_name, got_str, want)
print("strmode", [(n, s) for n, _, s in seen])
PY
