#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-zip-many-small-entries-bytes-positive
# @title: python-libarchive-c zip with 64 small entries roundtrip
# @description: Writes a zip with 64 single-byte entries, verifies the read-back archive has 64 entries each with size 1 and the correct payload byte.
# @timeout: 120
# @tags: usage, archive, zip
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "many.zip"
expected = [(f"e-{i:02d}.bin", bytes([i % 256])) for i in range(64)]

with libarchive.file_writer(str(arc), "zip") as writer:
    for n, b in expected:
        writer.add_file_from_memory(n, len(b), b)

got = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        body = b"".join(entry.get_blocks())
        got.append((entry.pathname, body))

assert len(got) == 64
assert got == expected, "mismatch"
print("entries", len(got))
print("first_byte", got[0][1][0])
print("last_byte", got[-1][1][0])
PY
