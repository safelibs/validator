#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-zip-deflate-level-3-roundtrip
# @title: python-libarchive-c zip with explicit deflate compression-level 3 roundtrips a single entry
# @description: Builds a zip archive in memory via custom_writer with options "zip:compression-level=3", writes a single highly-compressible payload, reads back via memory_reader, and asserts the pathname and payload are recovered intact, exercising the zip deflate compression-level 3 distinct from prior level 1 (r19), level 5 (r20), and level 9 (batch17) cases.
# @timeout: 60
# @tags: usage, archive, zip, deflate, level-3, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = b"r21 zip deflate level 3 payload block " * 32
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "zip", options="zip:compression-level=3") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload)

raw = buf.getvalue()
got_paths = []
got_payload = b""
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_paths.append(entry.pathname)
        got_payload = b"".join(bytes(b) for b in entry.get_blocks())

assert got_paths == ["doc.bin"], got_paths
assert got_payload == payload, (len(got_payload), len(payload))
print("zip-deflate-level3-ok", got_paths[0], "len=", len(got_payload))
PY
