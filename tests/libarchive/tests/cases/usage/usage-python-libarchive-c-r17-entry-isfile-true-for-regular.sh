#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-entry-isfile-true-for-regular
# @title: python-libarchive-c ArchiveEntry.isfile is True for regular ustar entries
# @description: Builds an in-memory ustar archive via custom_writer with two regular entries, reads back via memory_reader, and asserts entry.isfile is True and entry.isdir/entry.issym/entry.islnk are all False for every entry, exercising the file-type predicate surface on regular files.
# @timeout: 60
# @tags: usage, archive, ustar, filetype
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

entries = [
    ("file-one.txt", b"r17 isfile one\n"),
    ("file-two.bin", b"r17 isfile two payload bytes\n"),
]
buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    for name, body in entries:
        writer.add_file_from_memory(name, len(body), body)

raw = bytes(buf)
flags = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        flags[entry.pathname] = (entry.isfile, entry.isdir, entry.issym, entry.islnk)
        b"".join(entry.get_blocks())

for name, _ in entries:
    isfile, isdir, issym, islnk = flags[name]
    assert isfile is True, (name, flags[name])
    assert isdir is False, (name, flags[name])
    assert issym is False, (name, flags[name])
    assert islnk is False, (name, flags[name])
print("isfile-ok", flags)
PY
