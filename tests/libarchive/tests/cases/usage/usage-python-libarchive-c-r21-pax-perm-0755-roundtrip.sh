#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-pax-perm-0755-roundtrip
# @title: python-libarchive-c pax entry with permission 0755 roundtrips the permission bits
# @description: Builds a pax archive in memory via custom_writer with one entry whose permission is set to 0o755 through the add_file_from_memory keyword, reads back via memory_reader, and asserts the recovered entry mode masked to the low-nine permission bits equals 0o755, exercising the pax permission roundtrip at 0755 distinct from the existing 0644 (r20) and 0700 (batch20) cases.
# @timeout: 60
# @tags: usage, archive, pax, mode, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = b"r21 pax 0755 payload"
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "pax") as writer:
    writer.add_file_from_memory("exec.sh", len(payload), payload, permission=0o755)

raw = buf.getvalue()
modes = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        modes.append(entry.mode & 0o777)

assert modes == [0o755], modes
print("pax-perm-0755-ok", oct(modes[0]))
PY
