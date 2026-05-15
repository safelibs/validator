#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-tar-zstd-level-1-roundtrip
# @title: python-libarchive-c ustar with zstd filter at compression-level=1 roundtrips a payload
# @description: Builds a ustar archive in memory via custom_writer with filter_name="zstd" and options "compression-level=1" containing one named payload, reads back via memory_reader, and asserts the recovered payload equals the source byte-for-byte, exercising the zstd filter at the fastest compression level distinct from the level-3 and level-19 cases.
# @timeout: 60
# @tags: usage, archive, ustar, zstd, level1, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = (b"r19 zstd level-1 payload " * 64) + bytes(range(128))
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", "zstd", options="compression-level=1") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload)

raw = buf.getvalue()
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
print("zstd-level1-ok", len(payload))
PY
