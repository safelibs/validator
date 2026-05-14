#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-tar-zstd-level-3-roundtrip
# @title: python-libarchive-c ustar with zstd filter at compression-level=3 roundtrips a payload
# @description: Builds a ustar archive in memory via custom_writer with filter_name="zstd" and options "compression-level=3" containing one named payload, reads back via memory_reader, and asserts the recovered payload equals the source byte-for-byte, exercising the zstd filter with a non-default compression level on a memory writer.
# @timeout: 60
# @tags: usage, archive, ustar, zstd, level3, r18
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = (b"r18 zstd level-3 payload " * 32) + bytes(range(64))
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", "zstd", options="compression-level=3") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload)

raw = buf.getvalue()
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
print("zstd-level3-ok", len(payload))
PY
