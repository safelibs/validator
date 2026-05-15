#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-tar-mtime-2000-roundtrip
# @title: python-libarchive-c ustar entry with mtime=year-2000 roundtrips the modification time
# @description: Builds an in-memory ustar archive via custom_writer with one entry whose mtime is set to 946684800 (2000-01-01 00:00:00 UTC) via the add_file_from_memory mtime keyword, reads back via memory_reader, and asserts the recovered entry.mtime equals 946684800, exercising the ustar mtime roundtrip with a fixed Y2K boundary value distinct from prior 1970-epoch, 2030, or int32-max cases.
# @timeout: 60
# @tags: usage, archive, ustar, mtime, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = b"r20 ustar mtime 2000"
mtime = 946684800  # 2000-01-01T00:00:00Z
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload, mtime=mtime)

raw = buf.getvalue()
got_mtimes = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_mtimes.append(entry.mtime)

assert got_mtimes == [mtime], got_mtimes
print("mtime-2000-ok", got_mtimes)
PY
