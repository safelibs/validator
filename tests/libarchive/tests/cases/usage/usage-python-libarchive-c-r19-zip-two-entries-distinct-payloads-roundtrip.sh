#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-zip-two-entries-distinct-payloads-roundtrip
# @title: python-libarchive-c zip two-entry archive preserves each entry payload independently
# @description: Builds an in-memory zip archive via custom_writer with two named entries alpha.bin and beta.bin containing distinct binary payloads, reads back via memory_reader, and asserts each recovered payload equals its source byte-for-byte and the pathname order matches insertion, exercising the multi-entry zip writer-reader pair on a deterministic two-entry fixture.
# @timeout: 60
# @tags: usage, archive, zip, multi-entry, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

entries = [
    ("alpha.bin", b"r19 zip alpha " + bytes(range(0, 64))),
    ("beta.bin", b"r19 zip beta " + bytes(range(64, 128))),
]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "zip") as writer:
    for n, p in entries:
        writer.add_file_from_memory(n, len(p), p)

raw = buf.getvalue()
got_names = []
got_bodies = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_names.append(entry.pathname)
        got_bodies[entry.pathname] = b"".join(entry.get_blocks())

assert got_names == [n for n, _ in entries], got_names
for n, p in entries:
    assert got_bodies[n] == p, (n, len(got_bodies[n]), len(p))
print("zip-two-entries-ok", got_names)
PY
