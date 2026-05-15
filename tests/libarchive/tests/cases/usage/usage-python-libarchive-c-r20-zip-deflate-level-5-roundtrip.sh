#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-zip-deflate-level-5-roundtrip
# @title: python-libarchive-c zip deflate at compression-level=5 roundtrips a payload byte-for-byte
# @description: Builds a zip archive in memory via custom_writer with options "compression=deflate,compression-level=5" containing one named entry with a structured payload, reads back via memory_reader, and asserts the recovered payload equals the source byte-for-byte, exercising the zip deflate filter at the default middle compression level distinct from the level-1 and level-9 cases.
# @timeout: 60
# @tags: usage, archive, zip, deflate, level5, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = (b"r20 zip deflate level-5 payload " * 32) + bytes(range(96))
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "zip", options="compression=deflate,compression-level=5") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload)

raw = buf.getvalue()
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
print("zip-deflate-level5-ok", len(payload))
PY
