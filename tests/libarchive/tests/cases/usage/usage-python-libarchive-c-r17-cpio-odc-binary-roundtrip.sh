#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-cpio-odc-binary-roundtrip
# @title: python-libarchive-c cpio (odc) preserves binary payload across memory round-trip
# @description: Builds a cpio archive in memory using format "cpio" (odc by default) via custom_writer containing one entry with a 256-byte binary payload covering all byte values, decodes it back via memory_reader, and asserts the recovered payload matches the original byte-for-byte.
# @timeout: 60
# @tags: usage, archive, cpio, binary
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

payload = bytes(range(256))
buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "cpio") as writer:
    writer.add_file_from_memory("binary.bin", len(payload), payload)

raw = bytes(buf)
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
print("cpio-odc-ok", len(payload))
PY
