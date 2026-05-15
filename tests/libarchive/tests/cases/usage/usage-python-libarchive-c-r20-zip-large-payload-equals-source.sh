#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-zip-large-payload-equals-source
# @title: python-libarchive-c zip default deflate roundtrips a 64 KiB payload byte-for-byte
# @description: Builds a zip archive in memory via custom_writer with default options containing one entry holding a 64 KiB payload composed of a repeating block plus a unique trailer, reads back via memory_reader, and asserts the recovered payload size equals 65536 and the bytes equal the source, exercising the zip default writer with a payload large enough to span multiple deflate blocks distinct from the existing zip-large-payload test which uses a different size and tactic.
# @timeout: 60
# @tags: usage, archive, zip, large-payload, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = (b"r20 zip 64k block " * 3500)[:65000] + bytes(range(256)) * 2 + b"r20-trailer"
payload = payload[:65536]
# Pad/truncate to exactly 65536 bytes
if len(payload) < 65536:
    payload = payload + b"\x00" * (65536 - len(payload))
elif len(payload) > 65536:
    payload = payload[:65536]
assert len(payload) == 65536

buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "zip") as writer:
    writer.add_file_from_memory("big.bin", len(payload), payload)

raw = buf.getvalue()
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got == payload, (len(got) if got else None, len(payload))
assert len(got) == 65536, len(got)
print("zip-64k-ok", len(got))
PY
