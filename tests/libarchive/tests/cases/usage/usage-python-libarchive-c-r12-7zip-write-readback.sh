#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-7zip-write-readback
# @title: python-libarchive-c 7zip writer produces a 7z magic and reads back entries
# @description: Writes a small archive with format="7zip" via file_writer and asserts the on-disk magic is the documented 0x37 0x7A 0xBC 0xAF 0x27 0x1C signature, then reads the archive back via file_reader and verifies the inserted entries are present with their payloads.
# @timeout: 180
# @tags: usage, archive, 7zip, write
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
arc = tmpdir / "out.7z"
expected = {
    "alpha.txt": b"alpha-7z\n",
    "beta.txt": b"beta-7z payload\n",
}

with libarchive.file_writer(str(arc), "7zip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

magic = arc.read_bytes()[:6]
assert magic == b"7z\xbc\xaf\x27\x1c", magic.hex()

seen = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == expected, (sorted(seen), sorted(expected))
print("7zip-write", sorted(seen))
PY
