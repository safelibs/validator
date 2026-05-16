#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-tar-gzip-level-3-roundtrip
# @title: python-libarchive-c tar.gz with explicit gzip level 3 roundtrips a single entry
# @description: Builds a tar.gz archive in memory via custom_writer with filter "gzip" and options "gzip:compression-level=3", writes a single 2 KiB payload entry, reads back via memory_reader, and asserts the pathname and payload are recovered intact, exercising the gzip compression-level=3 filter option distinct from prior level 6 (batch14) and level 9 (r20) cases.
# @timeout: 60
# @tags: usage, archive, tar, gzip, level-3, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = b"r21 gzip level 3 payload chunk " * 64
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", filter_name="gzip", options="gzip:compression-level=3") as writer:
    writer.add_file_from_memory("entry.bin", len(payload), payload)

raw = buf.getvalue()
got_paths = []
got_payload = b""
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_paths.append(entry.pathname)
        got_payload = b"".join(bytes(b) for b in entry.get_blocks())

assert got_paths == ["entry.bin"], got_paths
assert got_payload == payload, (len(got_payload), len(payload))
print("gzip-level3-ok", got_paths[0], "len=", len(got_payload))
PY
