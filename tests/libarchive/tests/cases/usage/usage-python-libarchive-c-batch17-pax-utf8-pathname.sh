#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-pax-utf8-pathname
# @title: python-libarchive-c pax UTF-8 pathname round trip
# @description: Stores entries whose pathnames contain multi-byte UTF-8 characters (Greek, CJK, emoji-style code points) inside a pax archive, since pax extended headers are the standardized way to carry non-ASCII names. Reads the archive back and verifies every Unicode pathname round trips byte-for-byte through libarchive's pax extended-header decoder along with its payload.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-pax-utf8-pathname"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "utf8.pax"
expected = {
    "αβγ.txt": b"greek alpha-beta-gamma\n",
    "中文/data.bin": b"chinese subdir payload\n" * 4,
    "café-résumé.md": b"latin-1 supplement chars\n",
    "☃-snow.txt": b"snowman bmp codepoint\n",
}

with libarchive.file_writer(str(archive_path), "pax") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
# pax extended-header records carry a "path=" attribute when the name needs
# extended encoding. At least one of our entries must have triggered that
# path because of the non-ASCII byte sequences.
assert b"path=" in raw, raw[:512]

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, (sorted(got.keys()), sorted(expected.keys()))
print("pax-utf8", sorted(got.keys()))
PY
