#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-pax-mode-0644-roundtrip
# @title: python-libarchive-c pax entry with permission 0644 roundtrips the permission bits
# @description: Builds a pax archive in memory via custom_writer with one entry whose permission is set to 0o644 through the add_file_from_memory keyword, reads back via memory_reader, and asserts the recovered entry mode masked to the low-nine permission bits equals 0o644, exercising the pax permission roundtrip distinct from the existing batch20 pax 0700 case and other format mode tests.
# @timeout: 60
# @tags: usage, archive, pax, mode, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = b"r20 pax mode 0644 payload"
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "pax") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload, permission=0o644)

raw = buf.getvalue()
modes = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        modes.append(entry.mode & 0o777)

assert modes == [0o644], modes
print("pax-mode-0644-ok", oct(modes[0]))
PY
