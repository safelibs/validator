#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-tar-empty-payload-zero-size
# @title: python-libarchive-c ustar empty-payload entry reports size zero on readback
# @description: Builds a ustar archive in memory containing a single named entry added with an empty bytes payload via add_file_from_memory, reads back via memory_reader, and asserts entry.size equals zero and the iterated payload is the empty bytes object, exercising the zero-length-entry path through the writer and reader.
# @timeout: 60
# @tags: usage, archive, ustar, empty-payload, r18
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    writer.add_file_from_memory("empty.txt", 0, b"")

raw = buf.getvalue()
seen_size = None
seen_payload = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        seen_size = entry.size
        seen_payload = b"".join(entry.get_blocks())

assert seen_size == 0, seen_size
assert seen_payload == b"", seen_payload
print("empty-payload-ok", seen_size)
PY
