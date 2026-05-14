#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-pathname-unicode-roundtrip
# @title: python-libarchive-c pax entry pathname preserves a unicode (non-ASCII) string round-trip
# @description: Builds an in-memory pax archive via custom_writer with a single entry whose pathname contains the non-ASCII string "rondure-éè.txt", reads it back via memory_reader, and asserts entry.pathname returns the original unicode string unchanged, exercising the unicode pathname propagation through libarchive.
# @timeout: 60
# @tags: usage, archive, pax, unicode
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

name = "rondure-éè.txt"
payload = b"r17 unicode pathname payload\n"

buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "pax") as writer:
    writer.add_file_from_memory(name, len(payload), payload)

raw = bytes(buf)

seen_names = []
seen_body = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        seen_names.append(entry.pathname)
        seen_body = b"".join(entry.get_blocks())

assert seen_names == [name], (seen_names, name)
assert seen_body == payload, (seen_body, payload)
print("unicode-ok", seen_names)
PY
