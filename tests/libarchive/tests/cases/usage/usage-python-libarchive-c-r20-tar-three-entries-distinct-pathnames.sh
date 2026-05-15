#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-tar-three-entries-distinct-pathnames
# @title: python-libarchive-c ustar three-entry archive yields three distinct pathnames in iteration order
# @description: Builds an in-memory ustar archive via custom_writer with three named entries "a.txt", "b.txt", "c.txt" with single-character payloads, reads back via memory_reader, and asserts the recovered pathname list equals the source list in insertion order with len == 3 and no duplicates, exercising the ustar multi-entry pathname-order invariant on a three-entry archive distinct from prior two-entry and many-entry cases.
# @timeout: 60
# @tags: usage, archive, ustar, pathname-order, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

entries = [("a.txt", b"A"), ("b.txt", b"B"), ("c.txt", b"C")]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    for n, p in entries:
        writer.add_file_from_memory(n, len(p), p)

raw = buf.getvalue()
got = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got.append(entry.pathname)

expected = [n for n, _ in entries]
assert got == expected, (got, expected)
assert len(set(got)) == 3, got
print("ustar-three-entries-ok", got)
PY
