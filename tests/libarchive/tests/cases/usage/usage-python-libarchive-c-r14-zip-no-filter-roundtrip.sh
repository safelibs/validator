#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-zip-no-filter-roundtrip
# @title: python-libarchive-c file_writer zip with explicit None filter roundtrips entries
# @description: Builds a zip archive via libarchive.file_writer(path, "zip", None) - explicitly passing filter_name=None since deflate is built into the zip writer and there is no separate write_add_filter_deflate on noble - then reads it back and asserts every entry's pathname and payload round-trip in insertion order.
# @timeout: 60
# @tags: usage, archive, zip, filter-none
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
arc = tmpdir / "explicit.zip"
expected = [
    ("alpha.txt", b"zip explicit-filter alpha\n"),
    ("beta.txt", b"zip explicit-filter beta payload\n"),
    ("gamma.bin", bytes(range(40))),
]

with libarchive.file_writer(str(arc), "zip", None) as writer:
    for name, body in expected:
        writer.add_file_from_memory(name, len(body), body)

raw = arc.read_bytes()
assert raw[:2] == b"PK", raw[:2]

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert seen == expected, [(n, len(b)) for n, b in seen]
print("zip-none-filter", len(seen))
PY
