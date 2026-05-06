#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-pax-zero-byte-add-from-memory
# @title: python-libarchive-c pax zero-byte entry via add_file_from_memory
# @description: Adds a single zero-length payload entry to a pax archive via writer.add_file_from_memory(name, 0, b"") and verifies the read-back entry reports size 0 with no get_blocks() output. Pax-format coverage for the zero-length-from-memory edge case.
# @timeout: 120
# @tags: usage, archive, pax, zero-byte
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
arc = tmpdir / "zero.pax"

with libarchive.file_writer(str(arc), "pax") as writer:
    writer.add_file_from_memory("empty.bin", 0, b"")

records = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        body = b"".join(entry.get_blocks())
        records.append((entry.pathname, entry.size, len(body), body))

assert records == [("empty.bin", 0, 0, b"")], records
print("pax-zero-byte", records)
PY
