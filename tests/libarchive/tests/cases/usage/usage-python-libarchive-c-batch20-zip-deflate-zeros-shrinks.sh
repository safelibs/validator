#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-zip-deflate-zeros-shrinks
# @title: python-libarchive-c zip deflate compresses zeros payload to under 1KiB
# @description: Writes a 32 KiB all-zero payload into a zip archive with the default deflate compression and asserts the resulting on-disk archive is smaller than 1024 bytes, demonstrating that the deflate filter actually engaged on a maximally compressible input. Verifies the byte payload still round trips byte-for-byte through file_reader.
# @timeout: 120
# @tags: usage, archive, zip, deflate
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "zeros.zip"
payload = b"\x00" * (32 * 1024)

with libarchive.file_writer(str(arc), "zip") as writer:
    writer.add_file_from_memory("zeros.bin", len(payload), payload)

raw = arc.read_bytes()
assert raw[:2] == b"PK", raw[:2]
assert len(raw) < 1024, len(raw)

got = None
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        got = b"".join(entry.get_blocks())
assert got == payload, (len(got) if got is not None else None, len(payload))
print("zip-zeros-deflate-size", len(raw))
PY
