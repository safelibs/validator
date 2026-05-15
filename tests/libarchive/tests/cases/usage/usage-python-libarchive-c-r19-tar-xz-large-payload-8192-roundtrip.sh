#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-tar-xz-large-payload-8192-roundtrip
# @title: python-libarchive-c ustar+xz preserves an 8192-byte payload byte-for-byte
# @description: Builds an in-memory ustar archive with xz filter containing a single entry whose payload is exactly 8192 bytes of a deterministic repeating ASCII pattern, reads back via memory_reader, and asserts the recovered payload equals the source byte-for-byte, exercising the xz filter on a multi-block payload size distinct from prior single-block xz tests.
# @timeout: 60
# @tags: usage, archive, ustar, xz, large-payload, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

unit = b"r19xz" * 13  # 65 bytes
payload = (unit * (8192 // len(unit) + 1))[:8192]
assert len(payload) == 8192

buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", "xz") as writer:
    writer.add_file_from_memory("blob.bin", len(payload), payload)

raw = buf.getvalue()
got = None
got_size = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_size = entry.size
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
assert got_size == 8192, got_size
print("tar-xz-8192-ok", len(payload))
PY
