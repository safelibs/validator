#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-cpio-newc-roundtrip-payload-equal
# @title: python-libarchive-c cpio_newc roundtrip preserves payload bytes exactly
# @description: Builds an in-memory cpio archive in newc format using custom_writer with two named entries containing distinct payloads, reads back via memory_reader, and asserts each recovered payload equals the source byte-for-byte, exercising the newc cpio format on a multi-entry archive.
# @timeout: 60
# @tags: usage, archive, cpio, newc, r18
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

entries = [
    ("first.cpio.txt", b"r18 cpio newc payload one\n"),
    ("second.cpio.bin", bytes(range(96))),
]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "cpio_newc") as writer:
    for name, body in entries:
        writer.add_file_from_memory(name, len(body), body)

raw = buf.getvalue()
got = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

expected = dict(entries)
for name, body in entries:
    assert got[name] == body, (name, len(got[name]), len(body))
print("cpio-newc-ok", sorted(got))
PY
