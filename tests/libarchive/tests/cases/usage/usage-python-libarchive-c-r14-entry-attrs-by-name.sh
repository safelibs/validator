#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-entry-attrs-by-name
# @title: python-libarchive-c iterates ArchiveEntry attributes via getattr by name
# @description: Writes a single-entry tar with a deterministic mtime, opens it via file_reader, and asserts that getattr(entry, name) returns sensible values for the documented attribute set (pathname/size/mode/mtime/isfile/isdir/issym/islnk/filetype/linkname), ensuring the binding still surfaces every attribute name expected on noble.
# @timeout: 60
# @tags: usage, archive, tar, attributes
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
arc = tmpdir / "attrs.tar"
payload = b"attrs by name body\n"
target_mtime = 1650000000

with libarchive.file_writer(str(arc), "ustar") as writer:
    archive_p = writer._pointer
    with new_archive_entry() as ent:
        ArchiveEntry(None, ent).pathname = "named.txt"
        entry_set_filetype(ent, REGULAR_FILE)
        entry_set_perm(ent, 0o644)
        entry_set_size(ent, len(payload))
        entry_set_mtime(ent, target_mtime, 0)
        write_header(archive_p, ent)
        write_data(archive_p, payload, len(payload))
        write_finish_entry(archive_p)

attrs_to_probe = [
    "pathname", "size", "mode", "mtime",
    "isfile", "isdir", "issym", "islnk",
    "filetype", "linkname",
]

seen = None
body = None
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen = {name: getattr(entry, name) for name in attrs_to_probe}
        body = b"".join(entry.get_blocks())
        break

assert seen is not None, "no entries iterated"

assert body == payload, len(body)
assert seen["pathname"] == "named.txt", seen
assert seen["size"] == len(payload), seen
assert seen["mtime"] == target_mtime, seen
assert seen["isfile"] is True, seen
assert seen["isdir"] is False, seen
assert seen["issym"] is False, seen
assert seen["islnk"] is False, seen
# mode is an int; filetype is a dict-like or int depending on bindings;
# linkname is empty/None for a regular file.
assert isinstance(seen["mode"], int), seen
assert seen["filetype"] is not None, seen
assert seen["linkname"] in (None, "", "0"), seen
print("entry-attrs", seen["pathname"], seen["size"], seen["mtime"])
PY
