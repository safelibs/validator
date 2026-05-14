#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-pax-payload-hash-roundtrip
# @title: python-libarchive-c pax payload SHA-256 survives memory_writer/memory_reader round-trip
# @description: Builds a pax archive in memory via custom_writer with a single 4 KiB entry whose payload is pseudo-random bytes, decodes via memory_reader, and asserts the SHA-256 of the original payload equals the SHA-256 of the entry blocks read back, exercising binary fidelity across the pax codec.
# @timeout: 90
# @tags: usage, archive, pax, hash
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import hashlib
import os

import libarchive

payload = os.urandom(4096)
expected_hash = hashlib.sha256(payload).hexdigest()

buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "pax") as writer:
    writer.add_file_from_memory("payload.bin", len(payload), payload)

raw = bytes(buf)
assert len(raw) > 0

got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())

assert got is not None
assert hashlib.sha256(got).hexdigest() == expected_hash, (
    hashlib.sha256(got).hexdigest(),
    expected_hash,
)
print("pax-hash-ok", expected_hash)
PY
