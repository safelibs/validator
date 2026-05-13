#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-zip-entry-checksum-readback
# @title: python-libarchive-c zip readback yields the same SHA256 as the original payload
# @description: Builds a zip archive with a single entry whose payload is deterministic (256 bytes of 0..255), reads it back via libarchive.file_reader, computes SHA256 of the decompressed bytes via hashlib, and asserts the digest equals the SHA256 of the original payload — exercising the bytes-level fidelity of the zip writer/reader pair.
# @timeout: 180
# @tags: usage, archive, zip, checksum
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import hashlib
import sys
from pathlib import Path

import libarchive

tmpdir = Path(sys.argv[1])
archive_path = tmpdir / "out.zip"

payload = bytes(range(256))
expected_digest = hashlib.sha256(payload).hexdigest()

with libarchive.file_writer(str(archive_path), format_name="zip", filter_name=None) as writer:
    writer.add_file_from_memory("payload.bin", len(payload), payload)

assert archive_path.read_bytes()[:4] == b"PK\x03\x04"

got_payload = None
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        if entry.pathname == "payload.bin":
            got_payload = b"".join(entry.get_blocks())

assert got_payload is not None
assert len(got_payload) == 256, len(got_payload)
got_digest = hashlib.sha256(got_payload).hexdigest()
assert got_digest == expected_digest, (got_digest, expected_digest)
print("zip-sha256-ok", got_digest)
PY
