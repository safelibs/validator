#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-zip-bz2-filter-roundtrip
# @title: python-libarchive-c zip with bzip2 per-entry compression option roundtrips
# @description: Writes a zip archive with options="zip:compression=bzip2" and verifies the entries read back byte-for-byte, exercising the per-entry zip bzip2 method distinct from default deflate and the store option already covered.
# @timeout: 180
# @tags: usage, archive, zip, bzip2
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
arc = tmpdir / "bzip2.zip"
expected = {
    "alpha.txt": b"AAAA" * 64,
    "beta.txt": b"BBBB" * 64,
}

with libarchive.file_writer(str(arc), "zip", options="zip:compression=bzip2") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = arc.read_bytes()
assert raw[:2] == b"PK", raw[:2]

seen = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == expected, (sorted(seen), sorted(expected))
print("zip-bzip2", sorted(seen), len(raw))
PY
