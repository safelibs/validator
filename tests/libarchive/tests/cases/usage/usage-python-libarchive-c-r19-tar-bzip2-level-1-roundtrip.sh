#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-tar-bzip2-level-1-roundtrip
# @title: python-libarchive-c ustar with bzip2 filter at compression-level=1 roundtrips a payload
# @description: Builds an in-memory ustar archive via custom_writer with filter_name="bzip2" and options "compression-level=1" containing one named payload, reads back via memory_reader, and asserts the recovered payload equals the source byte-for-byte, exercising the bzip2 filter at the lowest block-size level distinct from the level-9 case.
# @timeout: 60
# @tags: usage, archive, ustar, bzip2, level1, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = (b"r19 bzip2 level-1 payload " * 40) + bytes(range(64))
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", "bzip2", options="compression-level=1") as writer:
    writer.add_file_from_memory("doc.bin", len(payload), payload)

raw = buf.getvalue()
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
print("bzip2-level1-ok", len(payload))
PY
