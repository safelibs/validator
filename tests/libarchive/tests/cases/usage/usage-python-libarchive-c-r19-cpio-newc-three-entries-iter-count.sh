#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-cpio-newc-three-entries-iter-count
# @title: python-libarchive-c cpio_newc three-entry archive iterates exactly three pathnames
# @description: Builds an in-memory cpio archive in newc format via custom_writer with three named entries a.txt b.txt c.txt and distinct payloads, reads back via memory_reader, and asserts both the iterated entry count is exactly three and the pathnames match the insertion order, exercising the newc cpio iteration count invariant.
# @timeout: 60
# @tags: usage, archive, cpio, newc, count, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

entries = [
    ("a.txt", b"r19 cpio newc a\n"),
    ("b.txt", b"r19 cpio newc b two\n"),
    ("c.txt", b"r19 cpio newc c three bytes here\n"),
]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "cpio_newc") as writer:
    for name, body in entries:
        writer.add_file_from_memory(name, len(body), body)

raw = buf.getvalue()
got_names = []
got_bodies = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_names.append(entry.pathname)
        got_bodies[entry.pathname] = b"".join(entry.get_blocks())

assert len(got_names) == 3, got_names
assert got_names == [n for n, _ in entries], got_names
for n, body in entries:
    assert got_bodies[n] == body, (n, got_bodies[n], body)
print("cpio-newc-three-ok", got_names)
PY
