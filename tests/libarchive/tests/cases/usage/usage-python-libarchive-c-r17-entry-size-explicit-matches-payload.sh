#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-entry-size-explicit-matches-payload
# @title: python-libarchive-c memory writer entry.size equals the explicit size argument on readback
# @description: Builds an in-memory ustar archive via custom_writer where add_file_from_memory is called with explicit size for each of three entries, reads back via memory_reader, and asserts entry.size matches the original payload length and the integer passed in the size argument for every entry.
# @timeout: 60
# @tags: usage, archive, ustar, entry-size
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

entries = [
    ("short.txt", b"abc\n"),
    ("medium.txt", b"r17 medium payload xyz\n"),
    ("longer.bin", bytes(range(64))),
]
buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    for name, body in entries:
        writer.add_file_from_memory(name, len(body), body)

raw = bytes(buf)
seen = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        seen[entry.pathname] = entry.size
        b"".join(entry.get_blocks())

for name, body in entries:
    assert seen[name] == len(body), (name, seen[name], len(body))
print("entry-size-ok", seen)
PY
