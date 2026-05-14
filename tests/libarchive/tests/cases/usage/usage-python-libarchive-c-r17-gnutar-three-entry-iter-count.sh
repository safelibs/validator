#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-gnutar-three-entry-iter-count
# @title: python-libarchive-c gnutar format iterates exactly three entries
# @description: Builds an in-memory gnutar archive containing three entries via custom_writer, reads it via memory_reader, and asserts the iteration produces exactly three ArchiveEntry objects with the expected pathnames, exercising the gnutar format on a fixed multi-entry payload.
# @timeout: 90
# @tags: usage, archive, gnutar, iter
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

names = ["a.txt", "b.txt", "c.txt"]
buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "gnutar") as writer:
    for n in names:
        body = ("gnutar r17 " + n).encode()
        writer.add_file_from_memory(n, len(body), body)

raw = bytes(buf)
seen = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        seen.append(entry.pathname)
        b"".join(entry.get_blocks())

assert seen == names, (seen, names)
assert len(seen) == 3, seen
print("gnutar-three-ok", seen)
PY
