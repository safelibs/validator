#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-tar-mtime-2025-roundtrip
# @title: python-libarchive-c ustar entry with mtime=2025-01-01 roundtrips the modification time
# @description: Builds an in-memory ustar archive via custom_writer with one entry whose mtime is set to 1735689600 (2025-01-01 00:00:00 UTC) via add_file_from_memory mtime keyword, reads back via memory_reader, and asserts the recovered entry.mtime equals 1735689600, exercising the ustar mtime roundtrip at a 2025 boundary distinct from prior 1970, 2000, 2030 and int32-max cases.
# @timeout: 60
# @tags: usage, archive, ustar, mtime, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = b"r21 tar mtime 2025"
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    writer.add_file_from_memory("doc.txt", len(payload), payload, mtime=1735689600)

raw = buf.getvalue()
mtimes = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        mtimes.append(entry.mtime)

assert mtimes == [1735689600], mtimes
print("tar-mtime-2025-ok", mtimes[0])
PY
