#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-tar-gzip-level-9-roundtrip
# @title: python-libarchive-c ustar with gzip filter at compression-level=9 roundtrips a payload
# @description: Builds a ustar archive in memory via custom_writer with filter_name="gzip" and options "compression-level=9" containing one named payload, reads back via memory_reader, and asserts the recovered payload equals the source byte-for-byte, exercising the gzip filter at the highest compression level distinct from prior unspecified-level gzip and other-level tests.
# @timeout: 60
# @tags: usage, archive, ustar, gzip, level9, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = (b"r20 gzip level-9 payload " * 64) + bytes(range(128))
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", "gzip", options="compression-level=9") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload)

raw = buf.getvalue()
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
print("gzip-level9-ok", len(payload))
PY
